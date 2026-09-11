// ============================================================
// EduAcademy - تفعيل الحساب بعد التسجيل (رمز تحقق عبر البريد)
//
// التدفق: إنشاء حساب (verified=0) → هذه الشاشة تُرسل رمزاً من 6 أرقام
// إلى بريد المستخدم (صالح 10 دقائق) → عند إدخاله صحيحاً يُفعَّل الحساب
// ويُسجَّل الدخول مباشرة.
// ============================================================

import 'package:flutter/material.dart';

import '../../models/models.dart';
import '../../services/auth_service.dart';
import '../../services/email/email_service.dart';
import '../../services/otp_service.dart';
import '../../services/storage_service.dart';
import '../../theme.dart';
import '../../widgets/common.dart';
import '../../widgets/keyboard_resume_fix.dart';
import '../../widgets/otp_panel.dart';

class VerifyEmailScreen extends StatefulWidget {
  final String email;
  final String name;
  final UserRole role;

  /// عند التفعيل بنجاح؛ إن كانت null تُغلق الشاشة بـ pop(true)
  final VoidCallback? onVerified;

  const VerifyEmailScreen({
    super.key,
    required this.email,
    required this.name,
    required this.role,
    this.onVerified,
  });

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  bool _done = false;

  Future<void> _onVerified() async {
    final s = StorageService.instance;
    await s.markVerified(widget.email);
    final user = s.userByEmail(widget.email);
    await AuthService.saveSession(
      widget.email.trim().toLowerCase(),
      user?.name ?? widget.name,
      role: (user?.role ?? widget.role).index,
    );
    if (!mounted) return;
    setState(() => _done = true);
    showSnack(context, 'تم تفعيل حسابك بنجاح، مرحباً ${widget.name} 👋');
    await Future<void>.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;
    if (widget.onVerified != null) {
      widget.onVerified!();
    } else {
      Navigator.of(context).pop(true);
    }
  }

  /// إلغاء التفعيل بعد تأكيد. نُبقي الرمز والحساب غير المفعّل:
  /// يمكن استكمال التفعيل من شاشة الدخول بنفس البيانات.
  Future<void> _cancel() async {
    final nav = Navigator.of(context);
    if (await _confirmCancel() && mounted) nav.pop(false);
  }

  Future<bool> _confirmCancel() async {
    final r = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card,
        title: const Text('إلغاء التفعيل؟'),
        content: const Text(
          'لم يُفعَّل حسابك بعد. إذا خرجت الآن يمكنك إعادة المحاولة لاحقاً '
          'بتسجيل الدخول بنفس البريد وكلمة المرور.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('متابعة التفعيل'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('خروج', style: TextStyle(color: AppColors.red)),
          ),
        ],
      ),
    );
    return r ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardResumeFix(
      child: PopScope(
        canPop: _done,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) _cancel();
        },
        child: Scaffold(
          appBar: AppBar(title: const Text('تفعيل الحساب')),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(
                    Icons.mark_email_unread_outlined,
                    size: 72,
                    color: AppColors.primary,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'تأكيد البريد الإلكتروني',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'أهلاً ${widget.name}! خطوة أخيرة: أدخل رمز التحقق المكوّن من '
                    '${OtpService.length} أرقام الذي أرسلناه إلى بريدك '
                    '(صالح ${OtpService.ttl.inMinutes} دقائق).',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.textDim,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 22),
                  _steps(),
                  const SizedBox(height: 24),
                  OtpPanel(
                    purpose: OtpPurpose.register,
                    email: widget.email,
                    recipientName: widget.name,
                    onVerified: _onVerified,
                    verifyLabel: 'تفعيل الحساب',
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: _cancel,
                    child: const Text('التفعيل لاحقاً'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _steps() => Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      _dot(1, true, Icons.person_add_alt_1),
      _line(true),
      _dot(2, true, Icons.mark_email_read),
      _line(_done),
      _dot(3, _done, Icons.check),
    ],
  );

  Widget _dot(int n, bool active, IconData icon) => Container(
    width: 30,
    height: 30,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: active ? AppColors.primary : AppColors.cardLight,
    ),
    child: Icon(
      icon,
      size: 16,
      color: active ? Colors.white : AppColors.textDim,
    ),
  );

  Widget _line(bool active) => Container(
    width: 40,
    height: 2,
    color: active ? AppColors.primary : AppColors.cardLight,
  );
}
