// منفّذ بريد وهمي للاختبارات: يسجّل ما أُرسل بدون أي اتصال شبكة
import 'package:eduacademy/services/email/email_sender.dart';

class SentMail {
  final String to, subject, text, html;
  SentMail(this.to, this.subject, this.text, this.html);
}

class FakeSender implements EmailSender {
  @override
  final bool supported;
  final bool fail;
  final List<SentMail> sent = [];
  FakeSender({this.supported = true, this.fail = false});

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
    if (fail) return const EmailSendResult.fail('smtp down');
    sent.add(SentMail(to, subject, text, html));
    return const EmailSendResult.ok();
  }
}
