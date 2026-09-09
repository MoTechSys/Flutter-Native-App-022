// ============================================================
// خدمة الترخيص - ملف التحكم عن بُعد هو المرجع دائماً
//   { "active": true|false, "code": "XXXX", "message": "..." }
//
// القواعد (بدقة):
// - active=true            => يفتح فوراً بدون أي كود (ويُمسح أي قفل سابق)
// - active=false           => يطلب كود التفعيل؛ إذا طابق "code" في الملف
//                             يُحفظ محلياً ويفتح في المرات التالية ما دام
//                             نفس الكود موجوداً في الملف (تغييره/حذفه يقفل)
// - الملف محذوف (404)      => يُقفل ولا يقبل أي كود
// - لا إنترنت              => آخر حالة معروفة (وأول تشغيل بلا إنترنت مسموح)
//
// معالجة الكاش: raw.githubusercontent يمر عبر CDN يحتفظ بالملف حتى 5 دقائق
// (حتى مع معامل كسر الكاش)، لذلك المصدر الأساسي هو GitHub API (يقرأ الكوميت
// الحالي مباشرة بلا كاش)، وعند فشله (حد الطلبات 60/ساعة) نرجع للملف الخام.
// ============================================================

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class LicenseService {
  /// عميل HTTP قابل للاستبدال (للاختبارات)
  static http.Client client = http.Client();

  static const String _owner = 'MoTechSys';
  static const String _repo = 'Flutter-Native-App-022';
  static const String _file = 'license.json';

  static const String _rawUrl =
      'https://raw.githubusercontent.com/$_owner/$_repo/main/$_file';
  static const String _apiUrl =
      'https://api.github.com/repos/$_owner/$_repo/contents/$_file?ref=main';

  static const String _kBlocked = 'lic_blocked';
  static const String _kMessage = 'lic_message';
  static const String _kCode = 'lic_code';
  static const String _kActivatedCode = 'lic_activated_code';
  static const String _kDeleted = 'lic_deleted';

  /// يُقرأ الملف عند كل تشغيل (وعند الضغط على "إعادة التحقق")
  static Future<LicenseState> check() async {
    final prefs = await SharedPreferences.getInstance();
    final remote = await _fetchRemote();

    if (remote == null) {
      // فشل الاتصال فقط (لا إنترنت) -> آخر حالة معروفة
      return _fromCache(prefs, offline: true);
    }

    if (remote.notFound) {
      // الملف أو المستودع محذوف => قفل كامل بدون كود
      const msg = 'انتهى ترخيص هذه النسخة. يرجى التواصل مع المطوّر.';
      await prefs.setBool(_kBlocked, true);
      await prefs.setBool(_kDeleted, true);
      await prefs.setString(_kMessage, msg);
      await prefs.setString(_kCode, '');
      return LicenseState(allowed: false, message: msg, codeAccepted: false);
    }

    final data = remote.data!;
    final active = data['active'] == true;
    final msg = (data['message'] ?? '').toString();
    final code = (data['code'] ?? '').toString().trim().toUpperCase();

    await prefs.setBool(_kDeleted, false);
    await prefs.setString(_kMessage, msg);
    await prefs.setString(_kCode, code);

    if (active) {
      // مفعّل من الملف => يفتح فوراً ويُمسح أي قفل سابق
      await prefs.setBool(_kBlocked, false);
      return LicenseState(allowed: true, message: msg, codeAccepted: true);
    }

    // غير مفعّل: هل سبق إدخال نفس الكود الموجود حالياً في الملف؟
    final saved = (prefs.getString(_kActivatedCode) ?? '').toUpperCase();
    final unlocked = code.isNotEmpty && saved == code;
    await prefs.setBool(_kBlocked, !unlocked);
    return LicenseState(
      allowed: unlocked,
      message: msg,
      codeAccepted: code.isNotEmpty,
    );
  }

  static LicenseState _fromCache(
    SharedPreferences prefs, {
    bool offline = false,
  }) {
    final blocked = prefs.getBool(_kBlocked) ?? false;
    final deleted = prefs.getBool(_kDeleted) ?? false;
    return LicenseState(
      allowed: !blocked,
      message: prefs.getString(_kMessage) ?? '',
      codeAccepted: !deleted && (prefs.getString(_kCode) ?? '').isNotEmpty,
      offline: offline,
    );
  }

  /// التحقق من الكود مقابل الملف؛ عند النجاح يُحفظ ويفتح
  static Future<bool> activate(String input) async {
    final prefs = await SharedPreferences.getInstance();
    // نحاول تحديث الكود من الملف أولاً حتى لا نقارن بنسخة قديمة
    final remote = await _fetchRemote();
    if (remote != null && remote.notFound) return false;
    if (remote?.data != null) {
      await prefs.setString(
        _kCode,
        (remote!.data!['code'] ?? '').toString().trim().toUpperCase(),
      );
    }
    final code = prefs.getString(_kCode) ?? '';
    if (code.isEmpty) return false; // لا يوجد كود مسموح حالياً
    final ok = input.trim().toUpperCase() == code;
    if (ok) {
      await prefs.setString(_kActivatedCode, code);
      await prefs.setBool(_kBlocked, false);
    }
    return ok;
  }

  // ---------------- جلب الملف بدون كاش ----------------
  // ملاحظة: لا نضع قيماً متعددة في Accept لأن GitHub يعيدها كما هي في
  // Content-Type فيفشل تحليل res.body (خطأ حقيقي وقع في النسخة السابقة).
  static const Map<String, String> _noCache = {
    'Cache-Control': 'no-cache, no-store, max-age=0',
    'Pragma': 'no-cache',
  };

  static Future<_Remote?> _fetchRemote() async {
    // 1) GitHub API: يقرأ الملف من المستودع مباشرة (بلا CDN)
    final api = await _fetchApi();
    if (api != null) return api;

    // 2) الملف الخام (قد يكون متأخراً حتى 5 دقائق) مع كاسر كاش
    try {
      final ts = DateTime.now().millisecondsSinceEpoch;
      final res = await client
          .get(Uri.parse('$_rawUrl?nocache=$ts'), headers: _noCache)
          .timeout(const Duration(seconds: 8));
      if (res.statusCode == 200) return _Remote(_decode(_utf8(res)));
      if (res.statusCode == 404) return _Remote.notFound();
    } catch (_) {}
    return null;
  }

  static Future<_Remote?> _fetchApi() async {
    try {
      final res = await client
          .get(
            Uri.parse(_apiUrl),
            headers: {..._noCache, 'Accept': 'application/vnd.github+json'},
          )
          .timeout(const Duration(seconds: 8));
      if (res.statusCode == 200) {
        final meta = jsonDecode(_utf8(res)) as Map<String, dynamic>;
        final b64 = (meta['content'] ?? '').toString().replaceAll(
          RegExp(r'\s'),
          '',
        );
        if (b64.isNotEmpty) {
          return _Remote(_decode(utf8.decode(base64Decode(b64))));
        }
      }
      if (res.statusCode == 404) return _Remote.notFound();
    } catch (_) {}
    return null; // 403 (حد الطلبات) أو فشل => نجرب الملف الخام
  }

  /// فك الجسم كـ UTF-8 مباشرة (تجنباً لفشل تحليل Content-Type)
  static String _utf8(http.Response res) => utf8.decode(res.bodyBytes);

  static Map<String, dynamic> _decode(String body) =>
      jsonDecode(body) as Map<String, dynamic>;
}

class _Remote {
  final Map<String, dynamic>? data;
  final bool notFound;
  _Remote(this.data) : notFound = false;
  _Remote.notFound() : data = null, notFound = true;
}

class LicenseState {
  final bool allowed;
  final String message;

  /// هل يوجد كود يمكن قبوله أصلاً (false عند حذف الملف)
  final bool codeAccepted;
  final bool offline;
  LicenseState({
    required this.allowed,
    this.message = '',
    this.codeAccepted = true,
    this.offline = false,
  });
}
