// ============================================================
// EduAcademy - خدمة البريد: قوالب الرسائل + الإرسال عبر EmailSender
//
// تُستخدم لإرسال رموز التحقق (OTP) في:
//   - تفعيل الحساب بعد التسجيل
//   - استعادة كلمة المرور
// ============================================================

import '../../config/mail_config.dart';
import 'email_sender.dart';

/// الغرض من الرمز (يؤثر على نص الرسالة فقط)
enum OtpPurpose { register, reset }

extension OtpPurposeX on OtpPurpose {
  String get title => this == OtpPurpose.register
      ? 'تفعيل حسابك في EduAcademy'
      : 'استعادة كلمة المرور - EduAcademy';

  String get intro => this == OtpPurpose.register
      ? 'شكراً لانضمامك إلى EduAcademy. لإتمام إنشاء حسابك أدخل رمز التحقق التالي في التطبيق:'
      : 'وصلنا طلب لإعادة تعيين كلمة مرور حسابك في EduAcademy. أدخل رمز التحقق التالي في التطبيق:';

  /// مفتاح التخزين (حتى لا يتداخل رمز التسجيل مع رمز الاستعادة)
  String get key => this == OtpPurpose.register ? 'register' : 'reset';
}

class EmailService {
  const EmailService._();

  /// المنفّذ الفعلي (قابل للاستبدال في الاختبارات)
  static EmailSender sender = createEmailSender();

  /// للاختبارات فقط: تجاوز بيانات الدخول المقروءة من --dart-define
  static ({String user, String pass})? debugCredentials;

  static String get _user => debugCredentials?.user ?? MailConfig.smtpUser;
  static String get _pass =>
      debugCredentials?.pass ?? MailConfig.normalizedPass;

  /// هل يمكن الإرسال فعلاً على هذه المنصة وبهذا البناء؟
  static bool get canSend =>
      sender.supported && _user.trim().isNotEmpty && _pass.trim().isNotEmpty;

  /// سبب عدم القدرة على الإرسال (يُعرض للمستخدم عند التراجع للرمز المعروض)
  static String get unavailableReason {
    if (!sender.supported) {
      return 'إرسال البريد غير متاح على نسخة الويب';
    }
    if (!canSend) return 'خادم البريد غير مضبوط في هذا البناء';
    return '';
  }

  /// إرسال رمز التحقق إلى بريد المستخدم
  static Future<EmailSendResult> sendOtp({
    required String to,
    required String code,
    required OtpPurpose purpose,
    required Duration validFor,
    String? recipientName,
  }) {
    if (!canSend) return Future.value(EmailSendResult.fail(unavailableReason));
    final minutes = validFor.inMinutes;
    return sender.send(
      host: MailConfig.smtpHost,
      port: MailConfig.smtpPort,
      username: _user,
      password: _pass,
      senderName: MailConfig.senderName,
      to: to,
      subject: '${purpose.title} - الرمز: $code',
      text: _plainText(code, purpose, minutes, recipientName),
      html: _html(code, purpose, minutes, recipientName),
    );
  }

  // ---------------- القوالب ----------------

  static String _greeting(String? name) =>
      (name == null || name.trim().isEmpty) ? 'مرحباً،' : 'مرحباً $name،';

  static String _plainText(
    String code,
    OtpPurpose purpose,
    int minutes,
    String? name,
  ) =>
      '''
${_greeting(name)}

${purpose.intro}

رمز التحقق: $code

الرمز صالح لمدة $minutes دقائق ولا يُستخدم إلا مرة واحدة.
إن لم تطلب هذا الرمز فتجاهل هذه الرسالة؛ لن يتغير شيء في حسابك.

فريق EduAcademy
''';

  static String _html(
    String code,
    OtpPurpose purpose,
    int minutes,
    String? name,
  ) {
    final spaced = code.split('').join(' ');
    return '''
<!DOCTYPE html>
<html dir="rtl" lang="ar">
<head><meta charset="UTF-8"></head>
<body style="margin:0;padding:0;background:#F3F4F6;font-family:Tahoma,Arial,sans-serif;">
  <table role="presentation" width="100%" cellspacing="0" cellpadding="0" style="background:#F3F4F6;padding:24px 0;">
    <tr><td align="center">
      <table role="presentation" width="100%" cellspacing="0" cellpadding="0" style="max-width:520px;background:#FFFFFF;border-radius:16px;overflow:hidden;box-shadow:0 2px 12px rgba(0,0,0,.06);">
        <tr>
          <td style="background:linear-gradient(135deg,#5B4BDB,#7C3AB8);background-color:#5B4BDB;padding:22px 28px;color:#fff;font-size:22px;font-weight:bold;text-align:right;">
            EduAcademy
          </td>
        </tr>
        <tr>
          <td style="padding:28px;color:#111827;font-size:15px;line-height:1.8;text-align:right;">
            <p style="margin:0 0 12px;">${_greeting(name)}</p>
            <p style="margin:0 0 20px;">${purpose.intro}</p>
            <div style="direction:ltr;text-align:center;margin:8px 0 20px;">
              <span style="display:inline-block;font-size:34px;letter-spacing:8px;font-weight:800;color:#5B4BDB;background:#EEF2FF;border:1px dashed #5B4BDB;border-radius:12px;padding:14px 22px;font-family:Consolas,'Courier New',monospace;">$spaced</span>
            </div>
            <p style="margin:0 0 8px;color:#374151;">⏱ الرمز صالح لمدة <b>$minutes دقائق</b> ويُستخدم مرة واحدة فقط.</p>
            <p style="margin:0;color:#6B7280;font-size:13px;">إن لم تطلب هذا الرمز فتجاهل هذه الرسالة؛ لن يتغير شيء في حسابك.</p>
          </td>
        </tr>
        <tr>
          <td style="padding:14px 28px;background:#F9FAFB;color:#9CA3AF;font-size:12px;text-align:center;">
            فريق EduAcademy · رسالة آلية، الرجاء عدم الرد عليها
          </td>
        </tr>
      </table>
    </td></tr>
  </table>
</body>
</html>
''';
  }
}
