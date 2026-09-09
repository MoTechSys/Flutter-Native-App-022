// ============================================================
// EduAcademy - شاشة الدورات (GridView) + إضافة/تعديل/حذف للمعلم
// ============================================================

import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/auth_service.dart';
import '../services/storage_service.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'course_details_screen.dart';

class CoursesScreen extends StatefulWidget {
  const CoursesScreen({super.key});
  @override
  State<CoursesScreen> createState() => _CoursesScreenState();
}

class _CoursesScreenState extends State<CoursesScreen> {
  bool _teacher = false;
  String _query = '';

  @override
  void initState() {
    super.initState();
    AuthService.isTeacher().then((v) {
      if (mounted) setState(() => _teacher = v);
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = StorageService.instance;
    return Scaffold(
      appBar: AppBar(title: const Text('الدورات التعليمية')),
      body: SafeArea(
        child: AnimatedBuilder(
          animation: s,
          builder: (context, _) {
            final list = s.courses
                .where(
                  (c) =>
                      _query.isEmpty ||
                      c.title.contains(_query) ||
                      c.category.contains(_query) ||
                      c.instructor.contains(_query),
                )
                .toList();
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                  child: TextField(
                    onChanged: (v) => setState(() => _query = v.trim()),
                    decoration: const InputDecoration(
                      hintText: 'ابحث عن دورة...',
                      prefixIcon: Icon(Icons.search),
                    ),
                  ),
                ),
                Expanded(
                  child: list.isEmpty
                      ? const EmptyState(
                          icon: Icons.menu_book,
                          text: 'لا توجد دورات',
                        )
                      : GridView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 90),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                mainAxisSpacing: 12,
                                crossAxisSpacing: 12,
                                childAspectRatio: 0.78,
                              ),
                          itemCount: list.length,
                          itemBuilder: (_, i) => _CourseTile(
                            course: list[i],
                            teacher: _teacher,
                            onEdit: () =>
                                showCourseForm(context, existing: list[i]),
                          ),
                        ),
                ),
              ],
            );
          },
        ),
      ),
      floatingActionButton: _teacher
          ? FloatingActionButton.extended(
              onPressed: () => showCourseForm(context),
              icon: const Icon(Icons.add),
              label: const Text('دورة جديدة'),
            )
          : null,
    );
  }
}

class _CourseTile extends StatelessWidget {
  final Course course;
  final bool teacher;
  final VoidCallback onEdit;
  const _CourseTile({
    required this.course,
    required this.teacher,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final s = StorageService.instance;
    final color = Color(course.color);
    final count = s.lessonsOf(course.id).length;
    final qCount = s.questionsOf(course.id).length;
    final progress = teacher ? 0.0 : s.progressOf(course.id);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CourseDetailsScreen(courseId: course.id),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 70,
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [color, color.withValues(alpha: 0.6)],
                ),
              ),
              child: Stack(
                children: [
                  const Center(
                    child: Icon(Icons.school, color: Colors.white, size: 34),
                  ),
                  if (teacher)
                    Positioned(
                      top: 2,
                      left: 2,
                      child: PopupMenuButton<String>(
                        iconColor: Colors.white,
                        onSelected: (v) async {
                          if (v == 'edit') onEdit();
                          if (v == 'del' && await confirmDelete(context)) {
                            await s.deleteCourse(course.id);
                            if (context.mounted) {
                              showSnack(context, 'تم حذف الدورة');
                            }
                          }
                        },
                        itemBuilder: (_) => const [
                          PopupMenuItem(value: 'edit', child: Text('تعديل')),
                          PopupMenuItem(value: 'del', child: Text('حذف')),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        course.category,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: color, fontSize: 11),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      course.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      teacher ? '$count درس • $qCount سؤال' : '$count درس',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textDim,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: teacher ? 1 : progress,
                        minHeight: 5,
                        backgroundColor: AppColors.cardLight,
                        color: teacher ? color.withValues(alpha: 0.35) : color,
                      ),
                    ),
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

/// نموذج إضافة/تعديل دورة
Future<void> showCourseForm(BuildContext context, {Course? existing}) async {
  final s = StorageService.instance;
  final isEdit = existing != null;
  final titleCtl = TextEditingController(text: existing?.title ?? '');
  final instCtl = TextEditingController(text: existing?.instructor ?? '');
  final catCtl = TextEditingController(text: existing?.category ?? '');
  final descCtl = TextEditingController(text: existing?.description ?? '');
  int color = existing?.color ?? 0xFF5B4BDB;
  final formKey = GlobalKey<FormState>();
  const palette = [
    0xFF5B4BDB,
    0xFF0EA5E9,
    0xFF1FA97A,
    0xFFF59E0B,
    0xFFE5484D,
    0xFF8B5CF6,
  ];

  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setState) => Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          20,
          20,
          MediaQuery.of(ctx).viewInsets.bottom + 20,
        ),
        child: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  isEdit ? 'تعديل الدورة' : 'إضافة دورة جديدة',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: titleCtl,
                  decoration: const InputDecoration(labelText: 'عنوان الدورة'),
                  validator: (v) => (v ?? '').trim().length < 3
                      ? 'العنوان 3 أحرف على الأقل'
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: instCtl,
                  decoration: const InputDecoration(labelText: 'اسم المدرّس'),
                  validator: (v) => (v ?? '').trim().isEmpty ? 'مطلوب' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: catCtl,
                  decoration: const InputDecoration(labelText: 'التصنيف'),
                  validator: (v) => (v ?? '').trim().isEmpty ? 'مطلوب' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: descCtl,
                  maxLines: 2,
                  decoration: const InputDecoration(labelText: 'الوصف'),
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 10,
                  children: palette
                      .map(
                        (c) => GestureDetector(
                          onTap: () => setState(() => color = c),
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: Color(c),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: color == c
                                    ? AppColors.text
                                    : Colors.transparent,
                                width: 3,
                              ),
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  icon: const Icon(Icons.save),
                  label: const Text('حفظ'),
                  onPressed: () async {
                    if (!formKey.currentState!.validate()) return;
                    final c = Course(
                      id: existing?.id ?? '',
                      title: titleCtl.text.trim(),
                      instructor: instCtl.text.trim(),
                      category: catCtl.text.trim(),
                      description: descCtl.text.trim(),
                      color: color,
                    );
                    if (isEdit) {
                      await s.updateCourse(c);
                    } else {
                      await s.addCourse(c);
                    }
                    if (ctx.mounted) Navigator.pop(ctx);
                    if (context.mounted) {
                      showSnack(
                        context,
                        isEdit ? 'تم تعديل الدورة' : 'تمت إضافة الدورة',
                      );
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
