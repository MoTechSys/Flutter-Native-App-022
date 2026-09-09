// ============================================================
// EduAcademy - الإحصائيات ومتابعة أداء الطلاب (معلم) / نتائجي (طالب)
// ============================================================

import 'package:flutter/material.dart';
import '../services/storage_service.dart';
import '../theme.dart';
import '../widgets/common.dart';

class StatsScreen extends StatelessWidget {
  final String email;
  final bool teacher;
  const StatsScreen({super.key, required this.email, required this.teacher});

  @override
  Widget build(BuildContext context) {
    final s = StorageService.instance;
    return Scaffold(
      appBar: AppBar(
        title: Text(teacher ? 'أداء الطلاب والإحصائيات' : 'نتائجي وإحصائياتي'),
      ),
      body: SafeArea(
        child: AnimatedBuilder(
          animation: s,
          builder: (context, _) {
            final results = teacher ? s.results : s.resultsOf(email);
            final passed = results.where((r) => r.passed).length;
            final students = s.students;
            // تقدّم الدورة: للمعلم = متوسط تقدّم كل الطلاب، للطالب = تقدّمه هو
            double courseProgress(String courseId) {
              if (!teacher) return s.progressOf(courseId, email);
              if (students.isEmpty) return 0;
              return students
                      .map((u) => s.progressOf(courseId, u.email))
                      .reduce((a, b) => a + b) /
                  students.length;
            }

            final avg = results.isEmpty
                ? 0.0
                : results.map((r) => r.percent).reduce((a, b) => a + b) /
                      results.length;
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 1.5,
                  children: [
                    StatTile(
                      icon: Icons.menu_book,
                      color: AppColors.primary,
                      value: '${s.courses.length}',
                      label: 'الدورات',
                    ),
                    if (teacher)
                      StatTile(
                        icon: Icons.people,
                        color: AppColors.teal,
                        value: '${students.length}',
                        label: 'الطلاب',
                      )
                    else
                      StatTile(
                        icon: Icons.check_circle,
                        color: AppColors.teal,
                        value:
                            '${s.completedCount(email)} / ${s.lessons.length}',
                        label: 'درس مكتمل',
                      ),
                    StatTile(
                      icon: Icons.quiz,
                      color: AppColors.orange,
                      value: '${results.length}',
                      label: 'اختبار مُنجز',
                    ),
                    StatTile(
                      icon: Icons.percent,
                      color: AppColors.green,
                      value: '${avg.round()}%',
                      label: 'متوسط الدرجات',
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // نسبة النجاح
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            SizedBox(
                              width: 70,
                              height: 70,
                              child: CircularProgressIndicator(
                                value: results.isEmpty
                                    ? 0
                                    : passed / results.length,
                                strokeWidth: 8,
                                backgroundColor: AppColors.cardLight,
                                color: AppColors.green,
                              ),
                            ),
                            Text(
                              results.isEmpty
                                  ? '0%'
                                  : '${(passed / results.length * 100).round()}%',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'نسبة النجاح',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '$passed ناجح من ${results.length} اختبار',
                                style: const TextStyle(
                                  color: AppColors.textDim,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // تقدم كل دورة
                Text(
                  teacher
                      ? 'متوسط تقدّم الطلاب في الدورات'
                      : 'تقدّمي في الدورات',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                ...s.courses.map((c) {
                  final p = courseProgress(c.id);
                  final color = Color(c.color);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    c.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                Text(
                                  '${(p * 100).round()}%',
                                  style: TextStyle(
                                    color: color,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: p,
                                minHeight: 7,
                                backgroundColor: AppColors.cardLight,
                                color: color,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 16),
                Text(
                  teacher ? 'نتائج الطلاب' : 'سجل نتائجي',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                if (results.isEmpty)
                  const SizedBox(
                    height: 120,
                    child: EmptyState(
                      icon: Icons.quiz,
                      text: 'لا توجد نتائج بعد',
                    ),
                  ),
                ...results.map((r) {
                  final c = s.courseById(r.courseId);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Card(
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor:
                              (r.passed ? AppColors.green : AppColors.red)
                                  .withValues(alpha: 0.15),
                          child: Icon(
                            r.passed ? Icons.check : Icons.close,
                            color: r.passed ? AppColors.green : AppColors.red,
                          ),
                        ),
                        title: Text(
                          c?.title ?? '—',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          teacher
                              ? '${s.userByEmail(r.studentEmail)?.name ?? r.studentEmail}\n${fmtDate(r.date)}'
                              : fmtDate(r.date),
                          style: const TextStyle(fontSize: 12),
                        ),
                        isThreeLine: teacher,
                        trailing: Text(
                          '${r.score}/${r.total}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: r.passed ? AppColors.green : AppColors.red,
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ],
            );
          },
        ),
      ),
    );
  }
}
