// ============================================================
// EduAcademy - إرسال البريد عبر SMTP (Android / Desktop)
// ============================================================

import 'dart:async';
import 'dart:io';

import 'package:mailer/mailer.dart' as mailer;
import 'package:mailer/smtp_server.dart';

import 'email_sender.dart';

EmailSender createEmailSender() => _SmtpEmailSender();

class _SmtpEmailSender implements EmailSender {
  @override
  bool get supported => true;

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
  }) async {
    final server = SmtpServer(
      host,
      port: port,
      username: username,
      password: password,
      // 465 = SSL مباشر، 587 = STARTTLS (mailer يرقّي الاتصال تلقائياً)
      ssl: port == 465,
      allowInsecure: false,
    );

    final message = mailer.Message()
      ..from = mailer.Address(username, senderName)
      ..recipients.add(to)
      ..subject = subject
      ..text = text
      ..html = html;

    try {
      await mailer.send(message, server).timeout(timeout);
      return const EmailSendResult.ok();
    } on TimeoutException {
      return const EmailSendResult.fail(
        'انتهت مهلة الاتصال بخادم البريد، تحقق من الإنترنت وأعد المحاولة',
      );
    } on mailer.SmtpClientAuthenticationException {
      return const EmailSendResult.fail(
        'رُفض الدخول إلى خادم البريد (تحقق من كلمة مرور التطبيق)',
      );
    } on SocketException {
      return const EmailSendResult.fail(
        'لا يمكن الوصول إلى خادم البريد، تحقق من اتصال الإنترنت',
      );
    } on mailer.MailerException catch (e) {
      final detail = e.problems.map((p) => p.msg).join('، ');
      return EmailSendResult.fail(
        detail.isEmpty ? 'فشل إرسال البريد' : 'فشل إرسال البريد: $detail',
      );
    } catch (_) {
      return const EmailSendResult.fail('حدث خطأ غير متوقع أثناء الإرسال');
    }
  }
}
