// ============================================================
// EduAcademy - صفحة إنشاء حساب (Form + Validation + اختيار الدور)
//   بعد الإنشاء يُنقل المستخدم إلى شاشة تفعيل البريد (رمز OTP عبر البريد)
// ============================================================

import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../services/storage_service.dart';
import '../../theme.dart';
import '../../widgets/common.dart';
import '../../widgets/keyboard_resume_fix.dart';
import 'verify_email_screen.dart';

class RegisterScreen extends StatefulWidget {
  /// يُستدعى عند اكتمال التفعيل (المستخدم مسجّل دخوله فعلاً)
  final VoidCallback? onRegistered;
  const RegisterScreen({super.key, this.onRegistered});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtl = TextEditingController();
  final _emailCtl = TextEditingController();
  final _passCtl = TextEditingController();
  final _confirmCtl = TextEditingController();
  bool _hide = true;
  bool _busy = false;
  UserRole _role = UserRole.student;

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _busy = true);
    final err = await StorageService.instance.register(
      _nameCtl.text.trim(),
      _emailCtl.text.trim(),
      _passCtl.text,
      role: _role,
    );
    if (!mounted) return;
    setState(() => _busy = false);
    if (err != null) {
      showSnack(context, err, error: true);
      return;
    }
    // الحساب أُنشئ غير مفعّل → نرسل رمز التحقق إلى بريده
    final email = _emailCtl.text.trim().toLowerCase();
    final name = _nameCtl.text.trim();
    final verified = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) =>
            VerifyEmailScreen(email: email, name: name, role: _role),
      ),
    );
    if (!mounted) return;
    if (verified == true) {
      // مسجّل دخوله الآن: نخرج من شاشة التسجيل ونبلّغ البوابة
      Navigator.pop(context, true);
      widget.onRegistered?.call();
    } else {
      showSnack(
        context,
        'لم يُفعّل الحساب بعد. سجّل الدخول بنفس البريد لإكمال التفعيل',
        error: true,
      );
      Navigator.pop(context, false);
    }
  }

  @override
  void dispose() {
    _nameCtl.dispose();
    _emailCtl.dispose();
    _passCtl.dispose();
    _confirmCtl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardResumeFix(
      child: Scaffold(
        appBar: AppBar(title: const Text('إنشاء حساب جديد')),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  const Icon(
                    Icons.person_add_alt_1,
                    size: 72,
                    color: AppColors.secondary,
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: _nameCtl,
                    decoration: const InputDecoration(
                      labelText: 'الاسم الكامل',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                    validator: (v) => (v ?? '').trim().length < 3
                        ? 'الاسم يجب أن يكون 3 أحرف على الأقل'
                        : null,
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _emailCtl,
                    keyboardType: TextInputType.emailAddress,
                    textDirection: TextDirection.ltr,
                    autofillHints: const [AutofillHints.email],
                    decoration: const InputDecoration(
                      labelText: 'البريد الإلكتروني',
                      helperText: 'سيُرسل رمز التحقق إلى هذا البريد',
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                    validator: validateEmail,
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _passCtl,
                    obscureText: _hide,
                    decoration: InputDecoration(
                      labelText: 'كلمة المرور',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _hide ? Icons.visibility_off : Icons.visibility,
                        ),
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
                    validator: (v) => v != _passCtl.text
                        ? 'كلمتا المرور غير متطابقتين'
                        : null,
                  ),
                  const SizedBox(height: 16),
                  // اختيار الدور
                  const Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: Text(
                      'نوع الحساب',
                      style: TextStyle(color: AppColors.textDim, fontSize: 13),
                    ),
                  ),
                  const SizedBox(height: 6),
                  SegmentedButton<UserRole>(
                    segments: const [
                      ButtonSegment(
                        value: UserRole.student,
                        icon: Icon(Icons.school_outlined),
                        label: Text('طالب'),
                      ),
                      ButtonSegment(
                        value: UserRole.teacher,
                        icon: Icon(Icons.co_present_outlined),
                        label: Text('معلم'),
                      ),
                    ],
                    selected: {_role},
                    onSelectionChanged: (s) => setState(() => _role = s.first),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _role == UserRole.teacher
                        ? 'المعلم: يدير الدورات والدروس والأسئلة ويتابع أداء الطلاب'
                        : 'الطالب: يشاهد الدروس ويسجّل الملاحظات ويحل الاختبارات',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.textDim,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: _busy ? null : _register,
                    icon: const Icon(Icons.check),
                    label: Text(_busy ? 'جارٍ الإنشاء...' : 'إنشاء الحساب'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
