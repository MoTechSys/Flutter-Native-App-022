// ============================================================
// EduAcademy - محرك رموز التحقق (OTP)
//
// المعايير المتبعة (OWASP / NIST 800-63B):
//   - رمز رقمي من 6 خانات مولَّد بـ Random.secure()
//   - صلاحية 10 دقائق، ويُستخدم مرة واحدة فقط
//   - حد أقصى 5 محاولات خاطئة ثم يُلغى الرمز
//   - لا يُحفظ الرمز نصاً؛ يُحفظ hash (SHA-256 + salt) في SharedPreferences
//     حتى يبقى صالحاً إذا خرج المستخدم من التطبيق وعاد خلال المدة
//   - مهلة 30 ثانية بين طلبَي إرسال (Resend cooldown)
//   - مقارنة بزمن ثابت (constant-time) لمنع هجمات التوقيت
//   - رمز التسجيل ورمز الاستعادة منفصلان (purpose)
// ============================================================

import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'email/email_service.dart';

/// نتيجة التحقق من رمز
enum OtpVerifyResult {
  ok,
  wrong,
  expired,
  tooManyAttempts,

  /// لا يوجد رمز صادر لهذا البريد (أو أُلغي)
  notIssued,
}

/// معلومات الرمز الصادر (بدون الرمز نفسه)
class OtpTicket {
  final String email;
  final DateTime expiresAt;
  final DateTime issuedAt;
  final int attempts;
  const OtpTicket({
    required this.email,
    required this.expiresAt,
    required this.issuedAt,
    required this.attempts,
  });

  bool get expired => DateTime.now().isAfter(expiresAt);
  Duration get remaining {
    final d = expiresAt.difference(DateTime.now());
    return d.isNegative ? Duration.zero : d;
  }
}

class OtpService {
  const OtpService._();

  static const Duration ttl = Duration(minutes: 10);
  static const Duration resendCooldown = Duration(seconds: 30);
  static const int maxAttempts = 5;
  static const int length = 6;

  /// للاختبارات: ساعة قابلة للتزييف
  static DateTime Function() now = DateTime.now;

  static final Random _rnd = Random.secure();

  static String _k(OtpPurpose p, String field) => 'otp_${p.key}_$field';

  static String generate() =>
      List.generate(length, (_) => _rnd.nextInt(10)).join();

  static String _hash(String code, String salt) =>
      base64Encode(sha256.convert(utf8.encode('$salt:$code')).bytes);

  static String _salt() =>
      base64Encode(List<int>.generate(16, (_) => _rnd.nextInt(256)));

  /// يُصدر رمزاً جديداً لهذا البريد ويحفظه (مُجزّأً) ويعيد الرمز نفسه
  /// (لإرساله بالبريد أو عرضه عند عدم توفر الإرسال)
  static Future<String> issue(OtpPurpose p, String email) async {
    final prefs = await SharedPreferences.getInstance();
    final code = generate();
    final salt = _salt();
    final t = now();
    await prefs.setString(_k(p, 'email'), email.trim().toLowerCase());
    await prefs.setString(_k(p, 'salt'), salt);
    await prefs.setString(_k(p, 'hash'), _hash(code, salt));
    await prefs.setInt(_k(p, 'issued'), t.millisecondsSinceEpoch);
    await prefs.setInt(_k(p, 'exp'), t.add(ttl).millisecondsSinceEpoch);
    await prefs.setInt(_k(p, 'attempts'), 0);
    return code;
  }

  /// الرمز الصادر حالياً لهذا الغرض (إن وُجد ولم يُلغَ)
  static Future<OtpTicket?> current(OtpPurpose p) async {
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString(_k(p, 'email'));
    final exp = prefs.getInt(_k(p, 'exp'));
    final issued = prefs.getInt(_k(p, 'issued'));
    if (email == null || exp == null || issued == null) return null;
    if (!prefs.containsKey(_k(p, 'hash'))) return null;
    return OtpTicket(
      email: email,
      expiresAt: DateTime.fromMillisecondsSinceEpoch(exp),
      issuedAt: DateTime.fromMillisecondsSinceEpoch(issued),
      attempts: prefs.getInt(_k(p, 'attempts')) ?? 0,
    );
  }

  /// كم ثانية متبقية قبل السماح بإعادة الإرسال (0 = مسموح الآن)
  static Future<int> resendWaitSeconds(OtpPurpose p) async {
    final t = await current(p);
    if (t == null) return 0;
    final wait = resendCooldown - now().difference(t.issuedAt);
    return wait.isNegative ? 0 : wait.inSeconds + 1;
  }

  /// التحقق من الرمز المُدخل؛ عند النجاح يُلغى الرمز (استخدام واحد)
  static Future<OtpVerifyResult> verify(
    OtpPurpose p,
    String email,
    String input,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final savedEmail = prefs.getString(_k(p, 'email'));
    final hash = prefs.getString(_k(p, 'hash'));
    final salt = prefs.getString(_k(p, 'salt'));
    final exp = prefs.getInt(_k(p, 'exp'));
    if (savedEmail == null || hash == null || salt == null || exp == null) {
      return OtpVerifyResult.notIssued;
    }
    if (savedEmail != email.trim().toLowerCase()) {
      return OtpVerifyResult.notIssued;
    }
    if (now().isAfter(DateTime.fromMillisecondsSinceEpoch(exp))) {
      await clear(p);
      return OtpVerifyResult.expired;
    }
    final attempts = (prefs.getInt(_k(p, 'attempts')) ?? 0) + 1;
    if (attempts > maxAttempts) {
      await clear(p);
      return OtpVerifyResult.tooManyAttempts;
    }
    final ok = _constantTimeEquals(_hash(input.trim(), salt), hash);
    if (ok) {
      await clear(p);
      return OtpVerifyResult.ok;
    }
    await prefs.setInt(_k(p, 'attempts'), attempts);
    if (attempts >= maxAttempts) {
      await clear(p);
      return OtpVerifyResult.tooManyAttempts;
    }
    return OtpVerifyResult.wrong;
  }

  /// إلغاء الرمز الحالي
  static Future<void> clear(OtpPurpose p) async {
    final prefs = await SharedPreferences.getInstance();
    for (final f in ['email', 'salt', 'hash', 'issued', 'exp', 'attempts']) {
      await prefs.remove(_k(p, f));
    }
  }

  static bool _constantTimeEquals(String a, String b) {
    if (a.length != b.length) return false;
    var diff = 0;
    for (var i = 0; i < a.length; i++) {
      diff |= a.codeUnitAt(i) ^ b.codeUnitAt(i);
    }
    return diff == 0;
  }
}
