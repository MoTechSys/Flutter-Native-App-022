// ============================================================
// EduAcademy - نسيت كلمة المرور (3 خطوات):
//   1) إدخال البريد المسجّل
//   2) توليد رمز OTP (6 أرقام) صالح 5 دقائق + نسخه
//   3) التحقق من الرمز ثم تعيين كلمة مرور جديدة
// ============================================================

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/storage_service.dart';
import '../../theme.dart';
import '../../widgets/common.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});
  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtl = TextEditingController();
  final _otpCtl = TextEditingController();
  final _passCtl = TextEditingController();
  final _confirmCtl = TextEditingController();

  int _step = 0; // 0 بريد، 1 رمز OTP، 2 كلمة جديدة
  String _otp = '';
  DateTime? _otpExpiry;
  int _attempts = 0;
  bool _busy = false;
  bool _hide = true;

  static const _otpTtl = Duration(minutes: 5);
  static const _maxAttempts = 5;

  bool get _otpExpired =>
      _otpExpiry == null || DateTime.now().isAfter(_otpExpiry!);

  String _genOtp() {
    final r = Random.secure();
    return List.generate(6, (_) => r.nextInt(10)).join();
  }

  Future<void> _next() async {
    if (!_formKey.currentState!.validate()) return;
    final s = StorageService.instance;
    setState(() => _busy = true);
    try {
      if (_step == 0) {
        final exists = await s.emailExists(_emailCtl.text.trim());
        if (!mounted) return;
        if (!exists) {
          showSnack(
            context,
            'لا يوجد حساب بهذا البريد الإلكتروني',
            error: true,
          );
          return;
        }
        _issueOtp();
        setState(() => _step = 1);
        showSnack(context, 'تم إنشاء رمز التحقق، انسخه ثم أدخله بالأسفل');
      } else if (_step == 1) {
        if (_otpExpired) {
          showSnack(context, 'انتهت صلاحية الرمز، أعد إرساله', error: true);
          return;
        }
        if (_otpCtl.text.trim() != _otp) {
          _attempts++;
          if (_attempts >= _maxAttempts) {
            _otp = '';
            _otpExpiry = null;
            showSnack(
              context,
              'تجاوزت عدد المحاولات، أعد إرسال رمز جديد',
              error: true,
            );
            setState(() {});
            return;
          }
          showSnack(
            context,
            'الرمز غير صحيح (المحاولة $_attempts من $_maxAttempts)',
            error: true,
          );
          return;
        }
        setState(() => _step = 2);
        showSnack(context, 'تم التحقق بنجاح، عيّن كلمة مرور جديدة');
      } else {
        await s.resetPassword(_emailCtl.text.trim(), _passCtl.text);
        if (!mounted) return;
        showSnack(context, 'تم تغيير كلمة المرور بنجاح، سجّل الدخول الآن');
        Navigator.pop(context);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _issueOtp() {
    _otp = _genOtp();
    _otpExpiry = DateTime.now().add(_otpTtl);
    _attempts = 0;
    _otpCtl.clear();
  }

  Future<void> _copyOtp() async {
    await Clipboard.setData(ClipboardData(text: _otp));
    if (mounted) showSnack(context, 'تم نسخ الرمز');
  }

  void _resend() {
    setState(_issueOtp);
    showSnack(context, 'تم إنشاء رمز جديد');
  }

  @override
  Widget build(BuildContext context) {
    const titles = ['التحقق من البريد', 'رمز التحقق (OTP)', 'كلمة مرور جديدة'];
    const hints = [
      'أدخل بريدك الإلكتروني المسجّل للتحقق من حسابك',
      'انسخ الرمز المولَّد ثم أدخله في الحقل للتحقق (صالح 5 دقائق)',
      'اختر كلمة مرور جديدة (6 أحرف على الأقل) وأكّدها',
    ];
    const icons = [Icons.mark_email_read, Icons.password, Icons.lock_reset];

    return Scaffold(
      appBar: AppBar(title: const Text('استعادة كلمة المرور')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                Icon(icons[_step], size: 72, color: AppColors.primary),
                const SizedBox(height: 12),
                Text(
                  titles[_step],
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  hints[_step],
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.textDim, height: 1.5),
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
                if (_step == 0) _emailField(),
                if (_step == 1) ..._otpStep(),
                if (_step == 2) ..._passwordStep(),
                const SizedBox(height: 28),
                ElevatedButton.icon(
                  onPressed: _busy ? null : _next,
                  icon: Icon(
                    _step == 0
                        ? Icons.arrow_back
                        : _step == 1
                        ? Icons.verified
                        : Icons.check,
                  ),
                  label: Text(
                    _step == 0
                        ? 'إنشاء رمز التحقق'
                        : _step == 1
                        ? 'تحقق من الرمز'
                        : 'حفظ كلمة المرور',
                  ),
                ),
                if (_step > 0)
                  TextButton(
                    onPressed: _busy
                        ? null
                        : () => setState(() {
                            _step = 0;
                            _otp = '';
                            _otpExpiry = null;
                          }),
                    child: const Text('تغيير البريد الإلكتروني'),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _emailField() => TextFormField(
    controller: _emailCtl,
    keyboardType: TextInputType.emailAddress,
    textDirection: TextDirection.ltr,
    decoration: const InputDecoration(
      labelText: 'البريد الإلكتروني',
      prefixIcon: Icon(Icons.email_outlined),
    ),
    validator: validateEmail,
  );

  List<Widget> _otpStep() => [
    // بطاقة الرمز المولَّد (نسخ)
    Card(
      color: AppColors.primary.withValues(alpha: 0.06),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            Text(
              'رمز التحقق للبريد ${_emailCtl.text.trim()}',
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
                      _otp.isEmpty ? '— — — — — —' : _otp.split('').join(' '),
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
                  onPressed: _otp.isEmpty ? null : _copyOtp,
                  icon: const Icon(Icons.copy, color: AppColors.primary),
                ),
              ],
            ),
            Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 4,
              children: [
                Icon(
                  _otpExpired ? Icons.timer_off : Icons.timer,
                  size: 14,
                  color: _otpExpired ? AppColors.red : AppColors.textDim,
                ),
                Text(
                  _otpExpired ? 'انتهت الصلاحية' : 'صالح لمدة 5 دقائق',
                  style: TextStyle(
                    fontSize: 12,
                    color: _otpExpired ? AppColors.red : AppColors.textDim,
                  ),
                ),
                TextButton(
                  onPressed: _busy ? null : _resend,
                  child: const Text('إعادة الإرسال'),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
    const SizedBox(height: 16),
    TextFormField(
      controller: _otpCtl,
      keyboardType: TextInputType.number,
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
      maxLength: 6,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      style: const TextStyle(fontSize: 22, letterSpacing: 8),
      decoration: const InputDecoration(
        labelText: 'أدخل رمز التحقق',
        prefixIcon: Icon(Icons.pin),
        counterText: '',
      ),
      validator: (v) {
        final t = (v ?? '').trim();
        if (t.isEmpty) return 'أدخل رمز التحقق';
        if (t.length != 6) return 'الرمز مكوّن من 6 أرقام';
        return null;
      },
    ),
  ];

  List<Widget> _passwordStep() => [
    TextFormField(
      controller: _passCtl,
      obscureText: _hide,
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
