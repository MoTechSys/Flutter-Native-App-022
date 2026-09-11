// ============================================================
// EduAcademy - إعدادات خادم البريد (SMTP) لإرسال رموز التحقق
//
// ⚠️ لا تُكتب بيانات الدخول هنا مباشرة لأن المستودع عام.
//    تُمرَّر وقت البناء عبر --dart-define (راجع BUILD_GUIDE.md §7):
//
//    flutter build apk --release \
//      --dart-define=SMTP_USER=you@gmail.com \
//      --dart-define=SMTP_PASS=xxxxxxxxxxxxxxxx
//
//    أو ضع الملف android/smtp.properties (مُتجاهَل في git) واستخدم
//    tool/build_release.sh الذي يقرأه ويمرّره تلقائياً.
//
// Gmail: يلزم "App Password" (16 حرفاً) من إعدادات الحساب مع تفعيل
//        التحقق بخطوتين؛ كلمة مرور الحساب العادية لا تعمل مع SMTP.
// ============================================================

class MailConfig {
  const MailConfig._();

  static const String smtpHost = String.fromEnvironment(
    'SMTP_HOST',
    defaultValue: 'smtp.gmail.com',
  );

  /// 587 = STARTTLS (الافتراضي لـ Gmail)، 465 = SSL مباشر
  static const int smtpPort = int.fromEnvironment(
    'SMTP_PORT',
    defaultValue: 587,
  );

  static const String smtpUser = String.fromEnvironment(
    'SMTP_USER',
    defaultValue: '',
  );

  static const String smtpPass = String.fromEnvironment(
    'SMTP_PASS',
    defaultValue: '',
  );

  /// الاسم الظاهر للمرسِل في صندوق الوارد
  static const String senderName = 'EduAcademy';

  /// هل بيانات SMTP متوفرة في هذا البناء؟
  static bool get configured =>
      smtpUser.trim().isNotEmpty && smtpPass.trim().isNotEmpty;

  /// كلمة مرور التطبيق من Google تأتي بمسافات (xxxx xxxx xxxx xxxx)؛
  /// نزيلها حتى تُقبل بأي شكل كُتبت.
  static String get normalizedPass => smtpPass.replaceAll(' ', '');
}
