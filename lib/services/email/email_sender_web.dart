// ============================================================
// EduAcademy - منفّذ الويب: المتصفح لا يدعم SMTP (لا sockets)
// عند الويب يُعرض رمز التحقق داخل التطبيق كبديل (Fallback).
// ============================================================

import 'email_sender.dart';

EmailSender createEmailSender() => _UnsupportedEmailSender();

class _UnsupportedEmailSender implements EmailSender {
  @override
  bool get supported => false;

  @override
  Future<EmailSendResult> send({
    required String host,
    required int port,
    required String username,
    required String password,
    required String senderName,
    required String to,
    required String subject,
    required String text,
    required String html,
    Duration timeout = const Duration(seconds: 20),
  }) async => const EmailSendResult.fail(
    'إرسال البريد غير مدعوم على الويب، استخدم الرمز المعروض',
  );
}
