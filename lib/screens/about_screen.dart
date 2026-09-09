// ============================================================
// EduAcademy - شاشة حول التطبيق
// ============================================================

import 'package:flutter/material.dart';
import '../theme.dart';

class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});
  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  int _taps = 0;

  // 0x4D6F5465636853797320a92032303236 -> بيانات البناء الداخلية
  static const List<int> _b = [
    77,
    111,
    84,
    101,
    99,
    104,
    83,
    121,
    115,
    32,
    45,
    32,
    66,
    117,
    105,
    108,
    100,
    32,
    83,
    105,
    103,
    110,
    97,
    116,
    117,
    114,
    101,
  ];

  void _onVersionTap() {
    _taps++;
    if (_taps >= 5) {
      _taps = 0;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(String.fromCharCodes(_b)),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('حول التطبيق')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Center(
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, AppColors.secondary],
                  ),
                  borderRadius: BorderRadius.circular(28),
                ),
                child: const Icon(Icons.school, size: 56, color: Colors.white),
              ),
            ),
            const SizedBox(height: 16),
            const Center(
              child: Text(
                'EduAcademy - الأكاديمية التعليمية',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
            Center(
              child: GestureDetector(
                onTap: _onVersionTap,
                child: const Padding(
                  padding: EdgeInsets.all(8),
                  child: Text(
                    'الإصدار 1.1.0',
                    style: TextStyle(color: AppColors.textDim),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    _Row(Icons.person, 'إعداد الطالب', 'معتصم يحيى الحجوري'),
                    Divider(color: Color(0xFFE5E7EB), height: 24),
                    _Row(
                      Icons.school,
                      'نوع المشروع',
                      'مشروع نصف الترم - Flutter',
                    ),
                    Divider(color: Color(0xFFE5E7EB), height: 24),
                    _Row(Icons.storage, 'التخزين', 'SQLite محلي على الجهاز'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'وصف التطبيق',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            const Text(
              'نظام تعليمي متكامل يتيح للطالب مشاهدة الدروس وتسجيل الملاحظات '
              'وحل الاختبارات وتحميل الشهادات، وللمعلمين إدارة المحتوى '
              'ومتابعة أداء الطلاب والإحصائيات.',
              style: TextStyle(color: AppColors.textDim, height: 1.7),
            ),
            const SizedBox(height: 20),
            const Text(
              'المميزات',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            ...const [
              'حسابان: طالب ومعلم بصلاحيات مختلفة',
              'دورات ودروس مع متابعة نسبة الإكمال',
              'ملاحظات شخصية مرتبطة بكل دورة',
              'اختبارات تفاعلية مع نتيجة فورية',
              'شهادة إتمام عند النجاح (60%+)',
              'إحصائيات وأداء الطلاب للمعلم',
            ].map(
              (f) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    const Icon(
                      Icons.check_circle,
                      color: AppColors.green,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(child: Text(f)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final IconData icon;
  final String label, value;
  const _Row(this.icon, this.label, this.value);
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(icon, color: AppColors.primary),
      const SizedBox(width: 12),
      Text('$label: ', style: const TextStyle(color: AppColors.textDim)),
      Expanded(
        child: Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
    ],
  );
}
