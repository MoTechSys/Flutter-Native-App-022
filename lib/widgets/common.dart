// ============================================================
// EduAcademy - عناصر واجهة مشتركة
// ============================================================

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme.dart';

final _numFmt = NumberFormat('#,###', 'en');
final _dateFmt = DateFormat('yyyy/MM/dd');

String fmtNum(num n) => _numFmt.format(n);
String fmtDate(DateTime d) => _dateFmt.format(d);

/// كارت متدرّج اللون
class GradientCard extends StatelessWidget {
  final Widget child;
  final Color color;
  final EdgeInsets padding;
  final VoidCallback? onTap;

  const GradientCard({
    super.key,
    required this.child,
    required this.color,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: padding,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [color.withValues(alpha: 0.35), AppColors.card],
          ),
          border: Border.all(color: color.withValues(alpha: 0.4)),
        ),
        child: child,
      ),
    );
  }
}

/// حلقة تقدّم دائرية مع أيقونة
class ProgressRing extends StatelessWidget {
  final double progress;
  final Color color;
  final IconData icon;
  final double size;

  const ProgressRing({
    super.key,
    required this.progress,
    required this.color,
    required this.icon,
    this.size = 60,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              value: progress,
              strokeWidth: 6,
              backgroundColor: AppColors.textDim.withValues(alpha: 0.2),
              color: color,
            ),
          ),
          Icon(icon, color: color, size: size * 0.42),
        ],
      ),
    );
  }
}

/// بلاطة إحصائية صغيرة
class StatTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String value;
  final String label;
  const StatTile({
    super.key,
    required this.icon,
    required this.color,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 26),
            const SizedBox(height: 6),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: AppColors.textDim, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}

/// حالة فارغة
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String text;
  const EmptyState({super.key, required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 70, color: AppColors.textDim),
            const SizedBox(height: 12),
            Text(
              text,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textDim,
                fontSize: 15,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// رسالة SnackBar (نجاح / خطأ)
void showSnack(BuildContext context, String msg, {bool error = false}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              error ? Icons.error_outline : Icons.check_circle_outline,
              color: Colors.white,
            ),
            const SizedBox(width: 10),
            Expanded(child: Text(msg)),
          ],
        ),
        backgroundColor: error ? AppColors.red : AppColors.green,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
}

/// التحقق من البريد الإلكتروني
String? validateEmail(String? v) {
  final s = (v ?? '').trim();
  if (s.isEmpty) return 'أدخل البريد الإلكتروني';
  if (!RegExp(r'^[\w\.\-]+@[\w\-]+\.[a-zA-Z]{2,}$').hasMatch(s)) {
    return 'صيغة البريد غير صحيحة (مثال: name@mail.com)';
  }
  return null;
}

/// التحقق من كلمة المرور
String? validatePassword(String? v) {
  final s = v ?? '';
  if (s.isEmpty) return 'أدخل كلمة المرور';
  if (s.length < 6) return 'كلمة المرور يجب أن تكون 6 أحرف على الأقل';
  return null;
}

/// تأكيد الحذف
Future<bool> confirmDelete(BuildContext context) async {
  final r = await showDialog<bool>(
    context: context,
    builder: (_) => AlertDialog(
      backgroundColor: AppColors.card,
      title: const Text('حذف السجل'),
      content: const Text('هل أنت متأكد من حذف هذا السجل؟'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('إلغاء'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('حذف', style: TextStyle(color: AppColors.red)),
        ),
      ],
    ),
  );
  return r ?? false;
}

/// حقل اختيار تاريخ
class DateField extends StatelessWidget {
  final DateTime value;
  final ValueChanged<DateTime> onChanged;
  const DateField({super.key, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        final d = await showDatePicker(
          context: context,
          initialDate: value,
          firstDate: DateTime(2000),
          lastDate: DateTime.now().add(const Duration(days: 1)),
        );
        if (d != null) onChanged(d);
      },
      borderRadius: BorderRadius.circular(14),
      child: InputDecorator(
        decoration: const InputDecoration(
          labelText: 'التاريخ',
          suffixIcon: Icon(Icons.calendar_today, color: AppColors.textDim),
        ),
        child: Text(fmtDate(value)),
      ),
    );
  }
}
