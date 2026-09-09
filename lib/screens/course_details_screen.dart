// ============================================================
// EduAcademy - تفاصيل الدورة: الدروس + الاختبار (تستقبل courseId)
// ============================================================

import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/auth_service.dart';
import '../services/storage_service.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'lesson_screen.dart';
import 'questions_screen.dart';
import 'quiz_screen.dart';

class CourseDetailsScreen extends StatefulWidget {
  final String courseId;
  const CourseDetailsScreen({super.key, required this.courseId});

  @override
  State<CourseDetailsScreen> createState() => _CourseDetailsScreenState();
}

class _CourseDetailsScreenState extends State<CourseDetailsScreen> {
  bool _teacher = false;

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
    return AnimatedBuilder(
      animation: s,
      builder: (context, _) {
        final course = s.courseById(widget.courseId);
        if (course == null) {
          return const Scaffold(body: Center(child: Text('الدورة غير موجودة')));
        }
        final color = Color(course.color);
        final lessons = s.lessonsOf(course.id);
        final questions = s.questionsOf(course.id);
        final progress = s.progressOf(course.id);
        final myResults = s
            .resultsOf(s.currentEmail)
            .where((r) => r.courseId == course.id)
            .toList();
        final best = myResults.isEmpty
            ? null
            : myResults.map((r) => r.percent).reduce((a, b) => a > b ? a : b);
        return Scaffold(
          appBar: AppBar(
            title: const Text('تفاصيل الدورة'),
            backgroundColor: color,
          ),
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
              children: [
                // رأس الدورة
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: LinearGradient(
                      colors: [color, color.withValues(alpha: 0.7)],
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        course.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 19,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${course.instructor} • ${course.category}',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                        ),
                      ),
                      if (course.description.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          course.description,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            height: 1.5,
                          ),
                        ),
                      ],
                      if (!_teacher) ...[
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: progress,
                                  minHeight: 7,
                                  backgroundColor: Colors.white24,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              '${(progress * 100).round()}%',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // الاختبار: الطالب يحلّه، المعلم يدير أسئلته
                Card(
                  child: ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.orange.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        _teacher ? Icons.edit_note : Icons.quiz,
                        color: AppColors.orange,
                      ),
                    ),
                    title: Text(
                      _teacher ? 'إدارة أسئلة الاختبار' : 'اختبار الدورة',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      _teacher
                          ? '${questions.length} سؤال • إضافة / تعديل / حذف'
                          : best == null
                          ? '${questions.length} سؤال • النجاح من 60%'
                          : '${questions.length} سؤال • أفضل نتيجة ${best.round()}% • ${myResults.length} محاولة',
                    ),
                    trailing: const Icon(Icons.chevron_left),
                    onTap: _teacher
                        ? () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => QuestionsScreen(course: course),
                            ),
                          )
                        : questions.isEmpty
                        ? () => showSnack(
                            context,
                            'لا توجد أسئلة لهذه الدورة بعد',
                            error: true,
                          )
                        : () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => QuizScreen(course: course),
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'الدروس (${lessons.length})',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                if (lessons.isEmpty)
                  const SizedBox(
                    height: 150,
                    child: EmptyState(
                      icon: Icons.play_lesson,
                      text: 'لا توجد دروس بعد',
                    ),
                  ),
                ...lessons.asMap().entries.map((e) {
                  final i = e.key;
                  final l = e.value;
                  final done = !_teacher && s.isCompleted(l.id);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Card(
                      child: ListTile(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                LessonScreen(lesson: l, color: color),
                          ),
                        ),
                        leading: CircleAvatar(
                          backgroundColor: done
                              ? AppColors.green
                              : color.withValues(alpha: 0.15),
                          child: done
                              ? const Icon(
                                  Icons.check,
                                  color: Colors.white,
                                  size: 20,
                                )
                              : Text(
                                  '${i + 1}',
                                  style: TextStyle(
                                    color: color,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                        title: Text(
                          l.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          '${l.durationMin} دقيقة',
                          style: const TextStyle(fontSize: 12),
                        ),
                        trailing: _teacher
                            ? PopupMenuButton<String>(
                                onSelected: (v) async {
                                  if (v == 'edit') {
                                    showLessonForm(
                                      context,
                                      course.id,
                                      existing: l,
                                    );
                                  }
                                  if (v == 'del' &&
                                      await confirmDelete(context)) {
                                    await s.deleteLesson(l.id);
                                    if (context.mounted) {
                                      showSnack(context, 'تم حذف الدرس');
                                    }
                                  }
                                },
                                itemBuilder: (_) => const [
                                  PopupMenuItem(
                                    value: 'edit',
                                    child: Text('تعديل'),
                                  ),
                                  PopupMenuItem(
                                    value: 'del',
                                    child: Text('حذف'),
                                  ),
                                ],
                              )
                            : const Icon(
                                Icons.play_circle_outline,
                                color: AppColors.textDim,
                              ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
          floatingActionButton: _teacher
              ? FloatingActionButton.extended(
                  backgroundColor: color,
                  onPressed: () => showLessonForm(context, course.id),
                  icon: const Icon(Icons.add),
                  label: const Text('درس جديد'),
                )
              : null,
        );
      },
    );
  }
}

/// نموذج إضافة/تعديل درس
Future<void> showLessonForm(
  BuildContext context,
  String courseId, {
  Lesson? existing,
}) async {
  final s = StorageService.instance;
  final isEdit = existing != null;
  final titleCtl = TextEditingController(text: existing?.title ?? '');
  final durCtl = TextEditingController(
    text: existing?.durationMin.toString() ?? '',
  );
  final contentCtl = TextEditingController(text: existing?.content ?? '');
  final formKey = GlobalKey<FormState>();

  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) => Padding(
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
                isEdit ? 'تعديل الدرس' : 'إضافة درس',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: titleCtl,
                decoration: const InputDecoration(labelText: 'عنوان الدرس'),
                validator: (v) => (v ?? '').trim().isEmpty ? 'مطلوب' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: durCtl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'المدة (دقيقة)'),
                validator: (v) => (int.tryParse(v ?? '') ?? 0) <= 0
                    ? 'أدخل رقماً صحيحاً'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: contentCtl,
                maxLines: 4,
                decoration: const InputDecoration(labelText: 'محتوى الدرس'),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                icon: const Icon(Icons.save),
                label: const Text('حفظ'),
                onPressed: () async {
                  if (!formKey.currentState!.validate()) return;
                  final l = Lesson(
                    id: existing?.id ?? '',
                    courseId: courseId,
                    title: titleCtl.text.trim(),
                    durationMin: int.parse(durCtl.text),
                    content: contentCtl.text.trim(),
                  );
                  if (isEdit) {
                    await s.updateLesson(l);
                  } else {
                    await s.addLesson(l);
                  }
                  if (ctx.mounted) Navigator.pop(ctx);
                  if (context.mounted) {
                    showSnack(
                      context,
                      isEdit ? 'تم تعديل الدرس' : 'تمت إضافة الدرس',
                    );
                  }
                },
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
