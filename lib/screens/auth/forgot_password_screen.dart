// ============================================================
// EduAcademy - نسيت كلمة المرور (3 خطوات):
//   1) إدخال البريد المسجّل  → يُرسل رمز تحقق (6 أرقام) إلى البريد
//   2) إدخال الرمز            → النظام يقارنه بالمرسَل (صالح 10 دقائق،
//                               5 محاولات)؛ خطأ = رسالة فشل ويبقى هنا
//   3) كلمة مرور جديدة        → UPDATE فعلي في SQLite ثم الرجوع للدخول
//
// إن تعذّر إرسال البريد (ويب / بلا إعداد SMTP) يُعرض الرمز داخل التطبيق
// مع زر نسخ حتى يبقى التدفق قابلاً للإكمال.
// ============================================================

import 'package:flutter/material.dart';

import '../../services/email/email_service.dart';
import '../../services/otp_service.dart';
import '../../services/storage_service.dart';
import '../../theme.dart';
import '../../widgets/common.dart';
import '../../widgets/keyboard_resume_fix.dart';
import '../../widgets/otp_panel.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});
  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtl = TextEditingController();
  final _passCtl = TextEditingController();
  final _confirmCtl = TextEditingController();

  int _step = 0; // 0 بريد، 1 رمز التحقق، 2 كلمة جديدة
  String _email = '';
  String _name = '';
  bool _busy = false;
  bool _hide = true;

  /// الخطوة 1: التحقق من البريد ثم الانتقال إلى الرمز (الإرسال يتم داخل OtpPanel)
  Future<void> _submitEmail() async {
    if (!_formKey.currentState!.validate()) return;
    final s = StorageService.instance;
    setState(() => _busy = true);
    try {
      final email = _emailCtl.text.trim().toLowerCase();
      final exists = await s.emailExists(email);
      if (!mounted) return;
      if (!exists) {
        showSnack(context, 'لا يوجد حساب بهذا البريد الإلكتروني', error: true);
        return;
      }
      _email = email;
      _name = s.userByEmail(email)?.name ?? '';
      setState(() => _step = 1);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// الخطوة 2 نجحت (OtpPanel تحقق من الرمز وألغاه)
  Future<void> _onOtpVerified() async {
    if (!mounted) return;
    setState(() => _step = 2);
    showSnack(context, 'تم التحقق بنجاح، عيّن كلمة مرور جديدة');
  }

  /// الخطوة 3: حفظ كلمة المرور الجديدة
  Future<void> _savePassword() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _busy = true);
    try {
      await StorageService.instance.resetPassword(_email, _passCtl.text);
      if (!mounted) return;
      showSnack(context, 'تم تغيير كلمة المرور بنجاح، سجّل الدخول الآن');
      Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _changeEmail() async {
    await OtpService.clear(OtpPurpose.reset);
    if (!mounted) return;
    setState(() {
      _step = 0;
      _email = '';
    });
  }

  @override
  void dispose() {
    _emailCtl.dispose();
    _passCtl.dispose();
    _confirmCtl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const titles = ['التحقق من البريد', 'رمز التحقق (OTP)', 'كلمة مرور جديدة'];
    final hints = [
      'أدخل بريدك الإلكتروني المسجّل وسنرسل إليه رمز تحقق',
      'أدخل الرمز المكوّن من ${OtpService.length} أرقام المرسَل إلى بريدك '
          '(صالح ${OtpService.ttl.inMinutes} دقائق)',
      'اختر كلمة مرور جديدة (6 أحرف على الأقل) وأكّدها',
    ];
    const icons = [Icons.mark_email_read, Icons.password, Icons.lock_reset];

    return KeyboardResumeFix(
      child: Scaffold(
        appBar: AppBar(title: const Text('استعادة كلمة المرور')),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Icon(icons[_step], size: 72, color: AppColors.primary),
                  const SizedBox(height: 12),
                  Text(
                    titles[_step],
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    hints[_step],
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.textDim,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 22),
                  // مؤشر الخطوات (3)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _dot(1, _step >= 0),
                      _line(_step >= 1),
                      _dot(2, _step >= 1),
                      _line(_step >= 2),
                      _dot(3, _step >= 2),
                    ],
                  ),
                  const SizedBox(height: 24),
                  if (_step == 0) ...[
                    _emailField(),
                    const SizedBox(height: 28),
                    ElevatedButton.icon(
                      onPressed: _busy ? null : _submitEmail,
                      icon: const Icon(Icons.send_outlined),
                      label: Text(
                        _busy ? 'جارٍ التحقق...' : 'إرسال رمز التحقق',
                      ),
                    ),
                  ],
                  if (_step == 1) ...[
                    OtpPanel(
                      key: ValueKey('reset-$_email'),
                      purpose: OtpPurpose.reset,
                      email: _email,
                      recipientName: _name,
                      onVerified: _onOtpVerified,
                    ),
                    TextButton(
                      onPressed: _busy ? null : _changeEmail,
                      child: const Text('تغيير البريد الإلكتروني'),
                    ),
                  ],
                  if (_step == 2) ...[
                    ..._passwordStep(),
                    const SizedBox(height: 28),
                    ElevatedButton.icon(
                      onPressed: _busy ? null : _savePassword,
                      icon: const Icon(Icons.check),
                      label: Text(_busy ? 'جارٍ الحفظ...' : 'حفظ كلمة المرور'),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _emailField() => TextFormField(
    controller: _emailCtl,
    keyboardType: TextInputType.emailAddress,
    textInputAction: TextInputAction.done,
    autofillHints: const [AutofillHints.email],
    textDirection: TextDirection.ltr,
    onFieldSubmitted: (_) => _busy ? null : _submitEmail(),
    decoration: const InputDecoration(
      labelText: 'البريد الإلكتروني',
      prefixIcon: Icon(Icons.email_outlined),
    ),
    validator: validateEmail,
  );

  List<Widget> _passwordStep() => [
    TextFormField(
      controller: _passCtl,
      obscureText: _hide,
      textInputAction: TextInputAction.next,
      autofillHints: const [AutofillHints.newPassword],
      decoration: InputDecoration(
        labelText: 'كلمة المرور الجديدة',
        prefixIcon: const Icon(Icons.lock_outline),
        suffixIcon: IconButton(
          icon: Icon(_hide ? Icons.visibility_off : Icons.visibility),
          onPressed: () => setState(() => _hide = !_hide),
        ),
      ),
      validator: validatePassword,
    ),
    const SizedBox(height: 14),
    TextFormField(
      controller: _confirmCtl,
      obscureText: _hide,
      textInputAction: TextInputAction.done,
      onFieldSubmitted: (_) => _busy ? null : _savePassword(),
      decoration: const InputDecoration(
        labelText: 'تأكيد كلمة المرور',
        prefixIcon: Icon(Icons.lock_reset),
      ),
      validator: (v) =>
          v != _passCtl.text ? 'كلمتا المرور غير متطابقتين' : null,
    ),
  ];

  Widget _dot(int n, bool active) => Container(
    width: 26,
    height: 26,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: active ? AppColors.primary : AppColors.cardLight,
    ),
    child: Text(
      '$n',
      style: TextStyle(
        color: active ? Colors.white : AppColors.textDim,
        fontWeight: FontWeight.bold,
        fontSize: 12,
      ),
    ),
  );

  Widget _line(bool active) => Container(
    width: 36,
    height: 2,
    color: active ? AppColors.primary : AppColors.cardLight,
  );
}
