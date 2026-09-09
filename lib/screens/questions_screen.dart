// ============================================================
// EduAcademy - إدارة أسئلة اختبار دورة (للمعلم) - CRUD كامل
// ============================================================

import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/storage_service.dart';
import '../theme.dart';
import '../widgets/common.dart';

class QuestionsScreen extends StatelessWidget {
  final Course course;
  const QuestionsScreen({super.key, required this.course});

  @override
  Widget build(BuildContext context) {
    final s = StorageService.instance;
    final color = Color(course.color);
    return Scaffold(
      appBar: AppBar(
        title: const Text('أسئلة الاختبار'),
        backgroundColor: color,
      ),
      body: SafeArea(
        child: AnimatedBuilder(
          animation: s,
          builder: (context, _) {
            final list = s.questionsOf(course.id);
            final attempts = s.results
                .where((r) => r.courseId == course.id)
                .toList();
            return Column(
              children: [
                // ملخص
                Container(
                  margin: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    gradient: LinearGradient(
                      colors: [color, color.withValues(alpha: 0.7)],
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              course.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${list.length} سؤال • ${attempts.length} محاولة من الطلاب',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.quiz, color: Colors.white, size: 36),
                    ],
                  ),
                ),
                Expanded(
                  child: list.isEmpty
                      ? const EmptyState(
                          icon: Icons.quiz_outlined,
                          text: 'لا توجد أسئلة بعد\nاضغط + لإضافة أول سؤال',
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 90),
                          itemCount: list.length,
                          itemBuilder: (_, i) => _QuestionCard(
                            index: i + 1,
                            q: list[i],
                            color: color,
                          ),
                        ),
                ),
              ],
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: color,
        onPressed: () => showQuestionForm(context, course.id),
        icon: const Icon(Icons.add),
        label: const Text('سؤال جديد'),
      ),
    );
  }
}

class _QuestionCard extends StatelessWidget {
  final int index;
  final Question q;
  final Color color;
  const _QuestionCard({
    required this.index,
    required this.q,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final s = StorageService.instance;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 6, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 14,
                    backgroundColor: color.withValues(alpha: 0.15),
                    child: Text(
                      '$index',
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      q.text,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (v) async {
                      if (v == 'edit') {
                        showQuestionForm(context, q.courseId, existing: q);
                      }
                      if (v == 'del' && await confirmDelete(context)) {
                        await s.deleteQuestion(q.id);
                        if (context.mounted) {
                          showSnack(context, 'تم حذف السؤال');
                        }
                      }
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(value: 'edit', child: Text('تعديل')),
                      PopupMenuItem(value: 'del', child: Text('حذف')),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ...q.options.asMap().entries.map((e) {
                final correct = e.key == q.correctIndex;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 4, right: 38),
                  child: Row(
                    children: [
                      Icon(
                        correct ? Icons.check_circle : Icons.circle_outlined,
                        size: 16,
                        color: correct ? AppColors.green : AppColors.textDim,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          e.value,
                          style: TextStyle(
                            fontSize: 13,
                            color: correct ? AppColors.green : AppColors.text,
                            fontWeight: correct
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}

/// نموذج إضافة/تعديل سؤال (Form + Validation)
Future<void> showQuestionForm(
  BuildContext context,
  String courseId, {
  Question? existing,
}) async {
  final s = StorageService.instance;
  final isEdit = existing != null;
  final textCtl = TextEditingController(text: existing?.text ?? '');
  final optCtls = List.generate(
    4,
    (i) => TextEditingController(
      text: (existing != null && i < existing.options.length)
          ? existing.options[i]
          : '',
    ),
  );
  int correct = existing?.correctIndex ?? 0;
  final formKey = GlobalKey<FormState>();

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
                  isEdit ? 'تعديل السؤال' : 'سؤال جديد',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: textCtl,
                  maxLines: 2,
                  decoration: const InputDecoration(labelText: 'نص السؤال'),
                  validator: (v) => (v ?? '').trim().length < 5
                      ? 'اكتب نص السؤال (5 أحرف على الأقل)'
                      : null,
                ),
                const SizedBox(height: 12),
                const Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: Text(
                    'الخيارات (حدد الإجابة الصحيحة)',
                    style: TextStyle(color: AppColors.textDim, fontSize: 13),
                  ),
                ),
                const SizedBox(height: 6),
                ...List.generate(
                  4,
                  (i) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        IconButton(
                          tooltip: 'الإجابة الصحيحة',
                          onPressed: () => setState(() => correct = i),
                          icon: Icon(
                            correct == i
                                ? Icons.check_circle
                                : Icons.radio_button_off,
                            color: correct == i
                                ? AppColors.green
                                : AppColors.textDim,
                          ),
                        ),
                        Expanded(
                          child: TextFormField(
                            controller: optCtls[i],
                            decoration: InputDecoration(
                              labelText: 'الخيار ${i + 1}',
                              isDense: true,
                            ),
                            validator: (v) =>
                                (v ?? '').trim().isEmpty ? 'مطلوب' : null,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  icon: const Icon(Icons.save),
                  label: const Text('حفظ'),
                  onPressed: () async {
                    if (!formKey.currentState!.validate()) return;
                    final opts = optCtls.map((c) => c.text.trim()).toList();
                    if (opts.toSet().length != opts.length) {
                      showSnack(
                        ctx,
                        'الخيارات يجب أن تكون مختلفة',
                        error: true,
                      );
                      return;
                    }
                    if (opts.any((o) => o.contains('|'))) {
                      showSnack(
                        ctx,
                        'لا يُسمح بالرمز | في الخيارات',
                        error: true,
                      );
                      return;
                    }
                    final q = Question(
                      id: existing?.id ?? '',
                      courseId: courseId,
                      text: textCtl.text.trim(),
                      options: opts,
                      correctIndex: correct,
                    );
                    if (isEdit) {
                      await s.updateQuestion(q);
                    } else {
                      await s.addQuestion(q);
                    }
                    if (ctx.mounted) Navigator.pop(ctx);
                    if (context.mounted) {
                      showSnack(
                        context,
                        isEdit ? 'تم تعديل السؤال' : 'تمت إضافة السؤال',
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
