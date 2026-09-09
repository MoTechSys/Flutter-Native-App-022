// ============================================================
// EduAcademy - مشاهدة الدرس + إضافة ملاحظة سريعة
// ============================================================

import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/storage_service.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'notes_screen.dart';

class LessonScreen extends StatelessWidget {
  final Lesson lesson;
  final Color color;
  const LessonScreen({super.key, required this.lesson, required this.color});

  @override
  Widget build(BuildContext context) {
    final s = StorageService.instance;
    return AnimatedBuilder(
      animation: s,
      builder: (context, _) {
        final l =
            s.lessons.where((x) => x.id == lesson.id).firstOrNull ?? lesson;
        final completed = s.isCompleted(l.id);
        return Scaffold(
          appBar: AppBar(title: const Text('الدرس'), backgroundColor: color),
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // "مشغّل الفيديو" (تمثيلي) باستخدام Stack
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Image.asset(
                        'assets/images/hero.png',
                        height: 190,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                      Container(
                        height: 190,
                        color: Colors.black.withValues(alpha: 0.45),
                      ),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.play_arrow,
                          color: Colors.white,
                          size: 40,
                        ),
                      ),
                      Positioned(
                        bottom: 10,
                        right: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '${l.durationMin}:00',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  l.title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(
                      Icons.schedule,
                      size: 16,
                      color: AppColors.textDim,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${l.durationMin} دقيقة',
                      style: const TextStyle(color: AppColors.textDim),
                    ),
                    const SizedBox(width: 14),
                    Icon(
                      completed
                          ? Icons.check_circle
                          : Icons.radio_button_unchecked,
                      size: 16,
                      color: completed ? AppColors.green : AppColors.textDim,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      completed ? 'مكتمل' : 'غير مكتمل',
                      style: TextStyle(
                        color: completed ? AppColors.green : AppColors.textDim,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'محتوى الدرس',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          l.content.isEmpty
                              ? 'لا يوجد محتوى نصي لهذا الدرس.'
                              : l.content,
                          style: const TextStyle(
                            height: 1.7,
                            color: AppColors.text,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // المعلم يراجع المحتوى فقط؛ الطالب يُكمل ويسجّل ملاحظات
                if (s.isTeacher)
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.people_outline),
                      title: const Text('أكمل هذا الدرس'),
                      trailing: Text(
                        '${s.students.where((u) => s.isCompleted(l.id, u.email)).length} / ${s.students.length} طالب',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  )
                else
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: completed
                                ? AppColors.textDim
                                : AppColors.green,
                          ),
                          onPressed: () async {
                            await s.toggleLesson(l);
                            if (context.mounted) {
                              showSnack(
                                context,
                                !completed
                                    ? 'تم تحديد الدرس كمكتمل ✓'
                                    : 'تم إلغاء الإكمال',
                              );
                            }
                          },
                          icon: Icon(completed ? Icons.undo : Icons.check),
                          label: Text(
                            completed ? 'إلغاء الإكمال' : 'إكمال الدرس',
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: color,
                          ),
                          onPressed: () => showNoteForm(
                            context,
                            defaultCourseId: l.courseId,
                          ),
                          icon: const Icon(Icons.note_add),
                          label: const Text('ملاحظة'),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
