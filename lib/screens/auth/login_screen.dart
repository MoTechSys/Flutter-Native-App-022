// ============================================================
// EduAcademy - صفحة تسجيل الدخول
// ============================================================

import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../services/auth_service.dart';
import '../../services/storage_service.dart';
import '../../theme.dart';
import '../../widgets/common.dart';
import '../../widgets/keyboard_resume_fix.dart';
import 'forgot_password_screen.dart';
import 'register_screen.dart';
import 'verify_email_screen.dart';

class LoginScreen extends StatefulWidget {
  final VoidCallback onLoggedIn;
  const LoginScreen({super.key, required this.onLoggedIn});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtl = TextEditingController();
  final _passCtl = TextEditingController();
  bool _hidePass = true;
  bool _busy = false;

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _busy = true);
    final user = await StorageService.instance.login(
      _emailCtl.text.trim(),
      _passCtl.text,
    );
    if (!mounted) return;
    setState(() => _busy = false);
    if (user == null) {
      showSnack(
        context,
        'البريد الإلكتروني أو كلمة المرور غير صحيحة',
        error: true,
      );
      return;
    }
    // حساب لم يُفعّل بريده بعد → نكمل التفعيل أولاً (البيانات صحيحة بالفعل)
    if ((user['verified'] ?? 1) != 1) {
      showSnack(
        context,
        'حسابك غير مفعّل، سنرسل رمز التحقق إلى بريدك',
        error: true,
      );
      final ok = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (_) => VerifyEmailScreen(
            email: user['email'] as String,
            name: (user['name'] ?? 'المستخدم') as String,
            role: ((user['role'] ?? 0) as int) == 1
                ? UserRole.teacher
                : UserRole.student,
          ),
        ),
      );
      if (!mounted) return;
      if (ok == true) widget.onLoggedIn();
      return;
    }
    await AuthService.saveSession(
      user['email'],
      user['name'],
      role: (user['role'] ?? 0) as int,
    );
    if (!mounted) return;
    showSnack(context, 'مرحباً ${user['name']} 👋');
    widget.onLoggedIn();
  }

  @override
  void dispose() {
    _emailCtl.dispose();
    _passCtl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardResumeFix(
      child: Scaffold(
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    // صورة من Assets
                    ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: Image.asset(
                        'assets/images/hero.png',
                        height: 180,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'EduAcademy',
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w900,
                        color: AppColors.primary,
                      ),
                    ),
                    const Text(
                      'الأكاديمية وإدارة الدورات التعليمية',
                      style: TextStyle(color: AppColors.textDim, fontSize: 15),
                    ),
                    const SizedBox(height: 28),
                    TextFormField(
                      controller: _emailCtl,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.email],
                      textDirection: TextDirection.ltr,
                      decoration: const InputDecoration(
                        labelText: 'البريد الإلكتروني',
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                      validator: validateEmail,
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _passCtl,
                      obscureText: _hidePass,
                      textInputAction: TextInputAction.done,
                      autofillHints: const [AutofillHints.password],
                      onFieldSubmitted: (_) => _busy ? null : _login(),
                      decoration: InputDecoration(
                        labelText: 'كلمة المرور',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _hidePass ? Icons.visibility_off : Icons.visibility,
                          ),
                          onPressed: () =>
                              setState(() => _hidePass = !_hidePass),
                        ),
                      ),
                      validator: (v) =>
                          (v ?? '').isEmpty ? 'أدخل كلمة المرور' : null,
                    ),
                    Align(
                      alignment: AlignmentDirectional.centerEnd,
                      child: TextButton(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ForgotPasswordScreen(),
                          ),
                        ),
                        child: const Text(
                          'نسيت كلمة المرور؟',
                          style: TextStyle(color: AppColors.secondary),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed: _busy ? null : _login,
                      icon: const Icon(Icons.login),
                      label: Text(_busy ? 'جارٍ الدخول...' : 'تسجيل الدخول'),
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      alignment: WrapAlignment.center,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        const Text(
                          'ليس لديك حساب؟',
                          style: TextStyle(color: AppColors.textDim),
                        ),
                        TextButton(
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => RegisterScreen(
                                onRegistered: widget.onLoggedIn,
                              ),
                            ),
                          ),
                          child: const Text(
                            'إنشاء حساب',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
