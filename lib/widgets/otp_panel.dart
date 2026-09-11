// ============================================================
// EduAcademy - لوحة رمز التحقق (OTP) المشتركة
//   تُستخدم في: تفعيل الحساب بعد التسجيل + استعادة كلمة المرور
//
// المسؤوليات:
//   - إصدار الرمز (OtpService) وإرساله بالبريد (EmailService)
//   - إن تعذّر الإرسال (ويب / بلا إعداد SMTP / خطأ شبكة) يُعرض الرمز
//     داخل التطبيق مع زر نسخ حتى يبقى التدفق قابلاً للإكمال
//   - عدّاد تنازلي لصلاحية الرمز (10 دقائق) ومهلة إعادة الإرسال (30 ث)
//   - حقل إدخال 6 أرقام يدعم اللصق والتحقق التلقائي عند اكتمال الخانات
//   - يستعيد الرمز الصادر عند الرجوع إلى الشاشة (لا يُلغى بالخروج)
// ============================================================

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../config/mail_config.dart';
import '../services/email/email_service.dart';
import '../services/otp_service.dart';
import '../theme.dart';
import 'common.dart';

class OtpPanel extends StatefulWidget {
  final OtpPurpose purpose;
  final String email;
  final String? recipientName;

  /// يُستدعى بعد نجاح التحقق (الرمز يُلغى تلقائياً)
  final Future<void> Function() onVerified;

  /// نص زر التحقق
  final String verifyLabel;

  const OtpPanel({
    super.key,
    required this.purpose,
    required this.email,
    required this.onVerified,
    this.recipientName,
    this.verifyLabel = 'تحقق من الرمز',
  });

  @override
  State<OtpPanel> createState() => OtpPanelState();
}

class OtpPanelState extends State<OtpPanel> {
  final _otpCtl = TextEditingController();
  final _otpFocus = FocusNode();
  Timer? _ticker;

  bool _sending = true;
  bool _verifying = false;

  /// الرمز المعروض داخل التطبيق (فقط عند تعذّر الإرسال أو وضع العرض)
  String? _shownCode;
  String _fallbackReason = '';
  bool _emailSent = false;
  String? _sendError;

  OtpTicket? _ticket;
  int _resendWait = 0;

  /// وضع عرض الرمز داخل التطبيق دائماً (للعرض التجريبي فقط):
  /// flutter build ... --dart-define=OTP_SHOW_IN_APP=true
  static const bool _alwaysShow = bool.fromEnvironment(
    'OTP_SHOW_IN_APP',
    defaultValue: false,
  );

  @override
  void initState() {
    super.initState();
    _bootstrap();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _otpCtl.dispose();
    _otpFocus.dispose();
    super.dispose();
  }

  /// عند الفتح: إن وُجد رمز سارٍ لنفس البريد نستعيده بدل إصدار جديد
  Future<void> _bootstrap() async {
    final existing = await OtpService.current(widget.purpose);
    if (existing != null &&
        existing.email == widget.email.trim().toLowerCase() &&
        !existing.expired) {
      if (!mounted) return;
      setState(() {
        _ticket = existing;
        _sending = false;
        _emailSent = true; // أُرسل سابقاً في نفس الجلسة
      });
      await _refreshResendWait();
      _otpFocus.requestFocus();
      return;
    }
    await send();
  }

  /// إصدار رمز جديد وإرساله
  Future<void> send() async {
    setState(() {
      _sending = true;
      _sendError = null;
      _shownCode = null;
      _emailSent = false;
      _otpCtl.clear();
    });
    final code = await OtpService.issue(widget.purpose, widget.email);
    final ticket = await OtpService.current(widget.purpose);

    String? shown;
    String reason = '';
    var sent = false;
    String? err;

    if (EmailService.canSend) {
      final r = await EmailService.sendOtp(
        to: widget.email,
        code: code,
        purpose: widget.purpose,
        validFor: OtpService.ttl,
        recipientName: widget.recipientName,
      );
      sent = r.sent;
      if (!sent) {
        err = r.error;
        shown = code; // تراجع: نعرض الرمز حتى لا يتعطل المستخدم
        reason = r.error;
      }
    } else {
      shown = code;
      reason = EmailService.unavailableReason;
    }
    if (_alwaysShow) shown = code;

    if (!mounted) return;
    setState(() {
      _ticket = ticket;
      _sending = false;
      _emailSent = sent;
      _sendError = err;
      _shownCode = shown;
      _fallbackReason = reason;
    });
    await _refreshResendWait();
    if (mounted) {
      showSnack(
        context,
        sent
            ? 'تم إرسال رمز التحقق إلى ${widget.email}'
            : 'تم إنشاء رمز التحقق، أدخله بالأسفل',
        error: err != null,
      );
      _otpFocus.requestFocus();
    }
  }

  Future<void> _refreshResendWait() async {
    final w = await OtpService.resendWaitSeconds(widget.purpose);
    if (mounted) setState(() => _resendWait = w);
  }

  void _tick() {
    if (!mounted) return;
    if (_resendWait > 0 || _ticket != null) {
      setState(() {
        if (_resendWait > 0) _resendWait--;
      });
    }
  }

  Future<void> _copy() async {
    if (_shownCode == null) return;
    await Clipboard.setData(ClipboardData(text: _shownCode!));
    if (mounted) showSnack(context, 'تم نسخ الرمز');
  }

  Future<void> _paste() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final digits = (data?.text ?? '').replaceAll(RegExp(r'\D'), '');
    if (digits.length >= OtpService.length) {
      _otpCtl.text = digits.substring(0, OtpService.length);
      _otpCtl.selection = TextSelection.collapsed(offset: _otpCtl.text.length);
      setState(() {});
      await verify();
    } else if (mounted) {
      showSnack(context, 'لا يوجد رمز صالح في الحافظة', error: true);
    }
  }

  /// التحقق من الرمز المُدخل
  Future<void> verify() async {
    final input = _otpCtl.text.trim();
    if (input.length != OtpService.length) {
      showSnack(
        context,
        'الرمز مكوّن من ${OtpService.length} أرقام',
        error: true,
      );
      return;
    }
    setState(() => _verifying = true);
    final r = await OtpService.verify(widget.purpose, widget.email, input);
    if (!mounted) return;
    switch (r) {
      case OtpVerifyResult.ok:
        await widget.onVerified();
        break;
      case OtpVerifyResult.wrong:
        final t = await OtpService.current(widget.purpose);
        if (!mounted) return;
        final left = OtpService.maxAttempts - (t?.attempts ?? 0);
        _otpCtl.clear();
        _otpFocus.requestFocus();
        showSnack(
          context,
          'الرمز غير صحيح، المتبقي $left ${left == 1 ? 'محاولة' : 'محاولات'}',
          error: true,
        );
        setState(() => _ticket = t);
        break;
      case OtpVerifyResult.expired:
        _otpCtl.clear();
        showSnack(context, 'انتهت صلاحية الرمز، أعد الإرسال', error: true);
        setState(() => _ticket = null);
        break;
      case OtpVerifyResult.tooManyAttempts:
        _otpCtl.clear();
        showSnack(
          context,
          'تجاوزت عدد المحاولات، أُلغي الرمز. أعد الإرسال',
          error: true,
        );
        setState(() => _ticket = null);
        break;
      case OtpVerifyResult.notIssued:
        _otpCtl.clear();
        showSnack(context, 'لا يوجد رمز صادر، أعد الإرسال', error: true);
        setState(() => _ticket = null);
        break;
    }
    if (mounted) setState(() => _verifying = false);
  }

  bool get _expired => _ticket == null || _ticket!.expired;

  String _mmss(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _statusCard(),
        const SizedBox(height: 16),
        _otpField(),
        const SizedBox(height: 8),
        _timerRow(),
        const SizedBox(height: 20),
        ElevatedButton.icon(
          onPressed: (_sending || _verifying || _expired) ? null : verify,
          icon: _verifying
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.verified_outlined),
          label: Text(_verifying ? 'جارٍ التحقق...' : widget.verifyLabel),
        ),
      ],
    );
  }

  // ---------------- بطاقة الحالة ----------------

  Widget _statusCard() {
    if (_sending) {
      return Card(
        color: AppColors.primary.withValues(alpha: 0.06),
        child: const Padding(
          padding: EdgeInsets.all(16),
          child: Row(
            children: [
              SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2.5),
              ),
              SizedBox(width: 14),
              Expanded(child: Text('جارٍ إرسال رمز التحقق إلى بريدك...')),
            ],
          ),
        ),
      );
    }

    // أُرسل بالبريد بنجاح (ولا يُعرض الرمز داخل التطبيق)
    if (_shownCode == null) {
      return Card(
        color: AppColors.green.withValues(alpha: 0.08),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.mark_email_read, color: AppColors.green),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _emailSent
                          ? 'أرسلنا رمز التحقق إلى بريدك الإلكتروني'
                          : 'رمز التحقق سارٍ لهذا البريد',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              SelectableText(
                widget.email,
                textDirection: TextDirection.ltr,
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'افتح بريدك (تحقق من مجلد الرسائل غير المرغوبة إن لم تجده)، '
                'ثم انسخ الرمز المكوّن من 6 أرقام وأدخله بالأسفل.',
                style: TextStyle(
                  color: AppColors.textDim,
                  fontSize: 12,
                  height: 1.5,
                ),
              ),
              if (MailConfig.senderName.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    'المرسِل: ${MailConfig.senderName}',
                    style: const TextStyle(
                      color: AppColors.textDim,
                      fontSize: 11,
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
    }

    // تراجع: الرمز معروض داخل التطبيق مع زر نسخ
    return Card(
      color: AppColors.primary.withValues(alpha: 0.06),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            if (_sendError != null || _fallbackReason.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Icon(
                      _sendError != null ? Icons.warning_amber : Icons.info,
                      size: 16,
                      color: _sendError != null
                          ? AppColors.orange
                          : AppColors.textDim,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        _sendError != null
                            ? 'لم يُرسل البريد: $_sendError'
                            : _fallbackReason,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textDim,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            Text(
              'رمز التحقق للبريد ${widget.email}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: AppColors.textDim, fontSize: 12),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: SelectableText(
                      _shownCode!.split('').join(' '),
                      textDirection: TextDirection.ltr,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 4,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                IconButton(
                  tooltip: 'نسخ الرمز',
                  onPressed: _copy,
                  icon: const Icon(Icons.copy, color: AppColors.primary),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ---------------- حقل الرمز ----------------

  Widget _otpField() => TextFormField(
    controller: _otpCtl,
    focusNode: _otpFocus,
    enabled: !_sending && !_verifying,
    keyboardType: TextInputType.number,
    textInputAction: TextInputAction.done,
    autofillHints: const [AutofillHints.oneTimeCode],
    textDirection: TextDirection.ltr,
    textAlign: TextAlign.center,
    maxLength: OtpService.length,
    inputFormatters: [
      FilteringTextInputFormatter.digitsOnly,
      LengthLimitingTextInputFormatter(OtpService.length),
    ],
    style: const TextStyle(fontSize: 24, letterSpacing: 10),
    decoration: InputDecoration(
      labelText: 'أدخل رمز التحقق',
      prefixIcon: const Icon(Icons.pin),
      suffixIcon: IconButton(
        tooltip: 'لصق الرمز',
        onPressed: (_sending || _verifying) ? null : _paste,
        icon: const Icon(Icons.content_paste_go),
      ),
      counterText: '',
    ),
    onChanged: (v) {
      // تحقق تلقائي عند اكتمال 6 أرقام (بالكتابة أو اللصق)
      if (v.length == OtpService.length && !_verifying && !_expired) {
        verify();
      }
    },
    onFieldSubmitted: (_) => verify(),
  );

  // ---------------- العدّاد + إعادة الإرسال ----------------

  Widget _timerRow() {
    final remaining = _ticket?.remaining ?? Duration.zero;
    final expired = _expired;
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      runSpacing: 4,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              expired ? Icons.timer_off : Icons.timer,
              size: 15,
              color: expired ? AppColors.red : AppColors.textDim,
            ),
            const SizedBox(width: 4),
            Text(
              _sending
                  ? '...'
                  : expired
                  ? 'انتهت صلاحية الرمز'
                  : 'صالح لمدة ${_mmss(remaining)}',
              style: TextStyle(
                fontSize: 12,
                color: expired ? AppColors.red : AppColors.textDim,
              ),
            ),
          ],
        ),
        TextButton.icon(
          onPressed: (_sending || _verifying || _resendWait > 0) ? null : send,
          icon: const Icon(Icons.refresh, size: 18),
          label: Text(
            _resendWait > 0
                ? 'إعادة الإرسال بعد $_resendWait ث'
                : 'إعادة الإرسال',
          ),
        ),
      ],
    );
  }
}
