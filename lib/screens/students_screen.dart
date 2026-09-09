// ============================================================
// EduAcademy - الطلاب (للمعلم): قائمة الطلاب + بحث + تفاصيل كل طالب
// ============================================================

import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/storage_service.dart';
import '../theme.dart';
import '../widgets/common.dart';

class StudentsScreen extends StatefulWidget {
  const StudentsScreen({super.key});
  @override
  State<StudentsScreen> createState() => _StudentsScreenState();
}

class _StudentsScreenState extends State<StudentsScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final s = StorageService.instance;
    return Scaffold(
      appBar: AppBar(title: const Text('الطلاب')),
      body: SafeArea(
        child: AnimatedBuilder(
          animation: s,
          builder: (context, _) {
            final all = s.students;
            final list = all
                .where(
                  (u) =>
                      _query.isEmpty ||
                      u.name.contains(_query) ||
                      u.email.contains(_query.toLowerCase()),
                )
                .toList();
            final active = all
                .where((u) => s.resultsOf(u.email).isNotEmpty)
                .length;
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: Row(
                    children: [
                      Expanded(
                        child: _Chip(
                          icon: Icons.people,
                          color: AppColors.primary,
                          label: 'طالب مسجّل',
                          value: '${all.length}',
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _Chip(
                          icon: Icons.quiz,
                          color: AppColors.orange,
                          label: 'حلّ اختباراً',
                          value: '$active',
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                  child: TextField(
                    onChanged: (v) => setState(() => _query = v.trim()),
                    decoration: const InputDecoration(
                      hintText: 'ابحث بالاسم أو البريد...',
                      prefixIcon: Icon(Icons.search),
                    ),
                  ),
                ),
                Expanded(
                  child: list.isEmpty
                      ? EmptyState(
                          icon: Icons.people_outline,
                          text: all.isEmpty
                              ? 'لا يوجد طلاب مسجّلون بعد\nسيظهر الطلاب هنا عند إنشاء حساباتهم'
                              : 'لا توجد نتائج للبحث',
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                          itemCount: list.length,
                          itemBuilder: (_, i) => _StudentTile(user: list[i]),
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label, value;
  const _Chip({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
  });
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 17,
                    color: color,
                  ),
                ),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textDim,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class _StudentTile extends StatelessWidget {
  final AppUser user;
  const _StudentTile({required this.user});

  @override
  Widget build(BuildContext context) {
    final s = StorageService.instance;
    final results = s.resultsOf(user.email);
    final certs = s.certificatesOf(user.email).length;
    final done = s.completedCount(user.email);
    final avg = s.avgOf(user.email);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Card(
        child: ListTile(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => StudentDetailsScreen(user: user)),
          ),
          leading: CircleAvatar(
            backgroundColor: AppColors.primary.withValues(alpha: 0.12),
            child: Text(
              user.name.isEmpty ? '?' : user.name.characters.first,
              style: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          title: Text(
            user.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Text(
            '$done درس مكتمل • ${results.length} اختبار • $certs شهادة',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12),
          ),
          trailing: results.isEmpty
              ? const Icon(Icons.chevron_left, color: AppColors.textDim)
              : Text(
                  '${avg.round()}%',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: avg >= 60 ? AppColors.green : AppColors.red,
                  ),
                ),
        ),
      ),
    );
  }
}

/// تفاصيل طالب (تستقبل بيانات الطالب من القائمة)
class StudentDetailsScreen extends StatelessWidget {
  final AppUser user;
  const StudentDetailsScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    final s = StorageService.instance;
    return Scaffold(
      appBar: AppBar(
        title: const Text('ملف الطالب'),
        actions: [
          IconButton(
            tooltip: 'حذف الحساب',
            icon: const Icon(Icons.delete_outline),
            onPressed: () async {
              final ok = await showDialog<bool>(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text('حذف حساب الطالب'),
                  content: Text(
                    'سيتم حذف حساب ${user.name} وكل ملاحظاته ونتائجه وتقدّمه. هل أنت متأكد؟',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('إلغاء'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text(
                        'حذف',
                        style: TextStyle(color: AppColors.red),
                      ),
                    ),
                  ],
                ),
              );
              if (ok == true) {
                await s.deleteStudent(user.email);
                if (context.mounted) {
                  Navigator.pop(context);
                  showSnack(context, 'تم حذف حساب الطالب');
                }
              }
            },
          ),
        ],
      ),
      body: SafeArea(
        child: AnimatedBuilder(
          animation: s,
          builder: (context, _) {
            final results = s.resultsOf(user.email);
            final certs = s.certificatesOf(user.email);
            final avg = s.avgOf(user.email);
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // رأس الملف (Stack)
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      height: 150,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        gradient: const LinearGradient(
                          colors: [AppColors.primary, Color(0xFF7C6CF0)],
                        ),
                      ),
                    ),
                    Column(
                      children: [
                        const CircleAvatar(
                          radius: 30,
                          backgroundColor: Colors.white,
                          child: Icon(
                            Icons.person,
                            size: 34,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          user.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          user.email,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                GridView.count(
                  crossAxisCount: 3,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 0.95,
                  children: [
                    StatTile(
                      icon: Icons.check_circle,
                      color: AppColors.secondary,
                      value: '${s.completedCount(user.email)}',
                      label: 'درس مكتمل',
                    ),
                    StatTile(
                      icon: Icons.quiz,
                      color: AppColors.orange,
                      value: '${results.length}',
                      label: 'اختبار',
                    ),
                    StatTile(
                      icon: Icons.percent,
                      color: avg >= 60 || results.isEmpty
                          ? AppColors.green
                          : AppColors.red,
                      value: '${avg.round()}%',
                      label: 'المتوسط',
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text(
                  'تقدّم الدورات',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 8),
                ...s.courses.map((c) {
                  final p = s.progressOf(c.id, user.email);
                  final color = Color(c.color);
                  final total = s.lessonsOf(c.id).length;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    c.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(4),
                                    child: LinearProgressIndicator(
                                      value: p,
                                      minHeight: 6,
                                      backgroundColor: AppColors.cardLight,
                                      color: color,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              '${(p * total).round()}/$total',
                              style: TextStyle(
                                color: color,
                                fontWeight: FontWeight.bold,
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
                  'نتائج الاختبارات (${results.length}) • شهادات: ${certs.length}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                if (results.isEmpty)
                  const SizedBox(
                    height: 110,
                    child: EmptyState(
                      icon: Icons.quiz_outlined,
                      text: 'لم يحل هذا الطالب أي اختبار بعد',
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
                          fmtDate(r.date),
                          style: const TextStyle(fontSize: 12),
                        ),
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
