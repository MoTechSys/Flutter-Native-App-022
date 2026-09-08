// ============================================================
// EduAcademy - الشهادات (النتائج الناجحة) + عرض الشهادة
// ============================================================

import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/auth_service.dart';
import '../services/storage_service.dart';
import '../theme.dart';
import '../widgets/common.dart';

class CertificatesScreen extends StatelessWidget {
  final String email;
  const CertificatesScreen({super.key, required this.email});

  @override
  Widget build(BuildContext context) {
    final s = StorageService.instance;
    return Scaffold(
      appBar: AppBar(title: const Text('الشهادات')),
      body: SafeArea(
        child: AnimatedBuilder(
          animation: s,
          builder: (context, _) {
            final certs = s.certificatesOf(email);
            if (certs.isEmpty) {
              return const EmptyState(
                icon: Icons.workspace_premium,
                text:
                    'لا توجد شهادات بعد\nانجح في اختبار دورة (60%+) للحصول على شهادة',
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: certs.length,
              itemBuilder: (_, i) {
                final r = certs[i];
                final course = s.courseById(r.courseId);
                final color = course == null
                    ? AppColors.primary
                    : Color(course.color);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Card(
                    child: ListTile(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              CertificateView(result: r, course: course),
                        ),
                      ),
                      leading: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.orange.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.workspace_premium,
                          color: AppColors.orange,
                        ),
                      ),
                      title: Text(
                        course?.title ?? 'دورة',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        '${fmtDate(r.date)} • ${r.percent.round()}%',
                        style: TextStyle(color: color, fontSize: 12),
                      ),
                      trailing: const Icon(
                        Icons.download,
                        color: AppColors.textDim,
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

/// عرض الشهادة (صفحة تستقبل البيانات)
class CertificateView extends StatelessWidget {
  final QuizResult result;
  final Course? course;
  const CertificateView({super.key, required this.result, this.course});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('الشهادة')),
      body: SafeArea(
        child: FutureBuilder<String>(
          future: AuthService.currentName(),
          builder: (context, snap) {
            final name = snap.data ?? '';
            return ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.orange, width: 3),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 12,
                        offset: Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.workspace_premium,
                        size: 64,
                        color: AppColors.orange,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'شهادة إتمام',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          color: AppColors.primary,
                        ),
                      ),
                      const Text(
                        'EduAcademy',
                        style: TextStyle(
                          color: AppColors.textDim,
                          letterSpacing: 2,
                        ),
                      ),
                      const Divider(height: 30),
                      const Text(
                        'تشهد الأكاديمية بأن',
                        style: TextStyle(color: AppColors.textDim),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        name,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'قد أتمّ بنجاح دورة',
                        style: TextStyle(color: AppColors.textDim),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        course?.title ?? '—',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _Meta('الدرجة', '${result.percent.round()}%'),
                          _Meta('التاريخ', fmtDate(result.date)),
                          _Meta('المدرّس', course?.instructor ?? '—'),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: () =>
                      showSnack(context, 'تم حفظ الشهادة في جهازك ✓'),
                  icon: const Icon(Icons.download),
                  label: const Text('تحميل الشهادة'),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _Meta extends StatelessWidget {
  final String label, value;
  const _Meta(this.label, this.value);
  @override
  Widget build(BuildContext context) => Expanded(
    child: Column(
      children: [
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        Text(
          label,
          style: const TextStyle(color: AppColors.textDim, fontSize: 11),
        ),
      ],
    ),
  );
}
