// ============================================================
// EduAcademy - ملاحظات الطالب (CRUD كامل)
// ============================================================

import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/storage_service.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'record_details_screen.dart';

class NotesScreen extends StatelessWidget {
  const NotesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = StorageService.instance;
    return Scaffold(
      appBar: AppBar(title: const Text('ملاحظاتي')),
      body: SafeArea(
        child: AnimatedBuilder(
          animation: s,
          builder: (context, _) {
            final list = s.notes;
            if (list.isEmpty) {
              return const EmptyState(
                icon: Icons.sticky_note_2,
                text: 'لا توجد ملاحظات بعد',
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
              itemCount: list.length,
              itemBuilder: (_, i) {
                final n = list[i];
                final course = s.courseById(n.courseId);
                final color = course == null
                    ? AppColors.primary
                    : Color(course.color);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Card(
                    child: InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => RecordDetailsScreen(
                            title: n.title,
                            color: color,
                            icon: Icons.sticky_note_2,
                            fields: {
                              'الدورة': course?.title ?? '—',
                              'التاريخ': fmtDate(n.date),
                              'الملاحظة': n.body,
                            },
                            onEdit: () => showNoteForm(context, existing: n),
                            onDelete: () => s.deleteNote(n.id),
                          ),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            Container(
                              width: 5,
                              height: 56,
                              decoration: BoxDecoration(
                                color: color,
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    n.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    n.body,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textDim,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${course?.title ?? '—'} • ${fmtDate(n.date)}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: color,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  visualDensity: VisualDensity.compact,
                                  icon: const Icon(
                                    Icons.edit_outlined,
                                    color: AppColors.primary,
                                    size: 20,
                                  ),
                                  onPressed: () =>
                                      showNoteForm(context, existing: n),
                                ),
                                IconButton(
                                  visualDensity: VisualDensity.compact,
                                  icon: const Icon(
                                    Icons.delete_outline,
                                    color: AppColors.red,
                                    size: 20,
                                  ),
                                  onPressed: () async {
                                    if (await confirmDelete(context)) {
                                      await s.deleteNote(n.id);
                                      if (context.mounted) {
                                        showSnack(context, 'تم حذف الملاحظة');
                                      }
                                    }
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showNoteForm(context),
        icon: const Icon(Icons.add),
        label: const Text('ملاحظة'),
      ),
    );
  }
}

/// نموذج إضافة/تعديل ملاحظة
Future<void> showNoteForm(
  BuildContext context, {
  Note? existing,
  String? defaultCourseId,
}) async {
  final s = StorageService.instance;
  if (s.courses.isEmpty) {
    showSnack(context, 'أضف دورة أولاً', error: true);
    return;
  }
  final isEdit = existing != null;
  String courseId = existing?.courseId ?? defaultCourseId ?? s.courses.first.id;
  if (s.courseById(courseId) == null) courseId = s.courses.first.id;
  final titleCtl = TextEditingController(text: existing?.title ?? '');
  final bodyCtl = TextEditingController(text: existing?.body ?? '');
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
                  isEdit ? 'تعديل الملاحظة' : 'ملاحظة جديدة',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: courseId,
                  decoration: const InputDecoration(labelText: 'الدورة'),
                  items: s.courses
                      .map(
                        (c) => DropdownMenuItem(
                          value: c.id,
                          child: Text(c.title, overflow: TextOverflow.ellipsis),
                        ),
                      )
                      .toList(),
                  onChanged: (v) => setState(() => courseId = v ?? courseId),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: titleCtl,
                  decoration: const InputDecoration(labelText: 'العنوان'),
                  validator: (v) => (v ?? '').trim().isEmpty ? 'مطلوب' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: bodyCtl,
                  maxLines: 4,
                  decoration: const InputDecoration(labelText: 'نص الملاحظة'),
                  validator: (v) => (v ?? '').trim().length < 3
                      ? 'اكتب 3 أحرف على الأقل'
                      : null,
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  icon: const Icon(Icons.save),
                  label: const Text('حفظ'),
                  onPressed: () async {
                    if (!formKey.currentState!.validate()) return;
                    final n = Note(
                      id: existing?.id ?? '',
                      courseId: courseId,
                      title: titleCtl.text.trim(),
                      body: bodyCtl.text.trim(),
                      date: existing?.date ?? DateTime.now(),
                    );
                    if (isEdit) {
                      await s.updateNote(n);
                    } else {
                      await s.addNote(n);
                    }
                    if (ctx.mounted) Navigator.pop(ctx);
                    if (context.mounted) {
                      showSnack(
                        context,
                        isEdit ? 'تم تعديل الملاحظة' : 'تم حفظ الملاحظة',
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
