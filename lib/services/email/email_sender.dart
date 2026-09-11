// ============================================================
// EduAcademy - واجهة إرسال البريد (تُنفَّذ حسب المنصة)
//   - Android/iOS/Desktop : SMTP عبر حزمة mailer  (email_sender_io.dart)
//   - Web                 : غير مدعوم (المتصفح لا يسمح بـ sockets)
//                           (email_sender_web.dart)
// ============================================================

import 'email_sender_web.dart'
    if (dart.library.io) 'email_sender_io.dart'
    as impl;

/// نتيجة محاولة إرسال بريد
class EmailSendResult {
  final bool sent;

  /// سبب الفشل بالعربية (فارغ عند النجاح)
  final String error;
  const EmailSendResult.ok() : sent = true, error = '';
  const EmailSendResult.fail(this.error) : sent = false;
}

abstract class EmailSender {
  /// هل تستطيع هذه المنصة الإرسال أصلاً؟
  bool get supported;

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
  });
}

/// يُرجع المنفّذ المناسب للمنصة الحالية
EmailSender createEmailSender() => impl.createEmailSender();
