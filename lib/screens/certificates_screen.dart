// ============================================================
// EduAcademy - الشهادات (النتائج الناجحة) + عرض الشهادة وتحميلها فعلياً
// ============================================================

import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/certificate_exporter.dart';
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
                        Icons.chevron_left,
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

/// عرض الشهادة (صفحة تستقبل البيانات) مع تحميل/مشاركة حقيقيين
class CertificateView extends StatefulWidget {
  final QuizResult result;
  final Course? course;
  const CertificateView({super.key, required this.result, this.course});

  @override
  State<CertificateView> createState() => _CertificateViewState();
}

class _CertificateViewState extends State<CertificateView> {
  final _key = GlobalKey();
  bool _busy = false;

  String get _fileName =>
      'EduAcademy_Certificate_${widget.result.id.isEmpty ? DateTime.now().millisecondsSinceEpoch : widget.result.id}.png';

  Future<void> _download() async {
    setState(() => _busy = true);
    try {
      final bytes = await CertificateExporter.capture(_key);
      final path = await CertificateExporter.saveToDevice(bytes, _fileName);
      if (!mounted) return;
      if (path != null) {
        showSnack(context, 'تم حفظ الشهادة في جهازك ✓');
        // إتاحة الفتح/الإرسال مباشرة بعد الحفظ
        await CertificateExporter.share(
          bytes,
          _fileName,
          'شهادة إتمام دورة ${widget.course?.title ?? ''} - EduAcademy',
        );
      } else {
        // الويب: نافذة المشاركة/التنزيل
        await CertificateExporter.share(
          bytes,
          _fileName,
          'شهادة إتمام - EduAcademy',
        );
      }
    } catch (e) {
      if (mounted) {
        showSnack(context, 'تعذّر حفظ الشهادة، حاول مرة أخرى', error: true);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _share() async {
    setState(() => _busy = true);
    try {
      final bytes = await CertificateExporter.capture(_key);
      await CertificateExporter.share(
        bytes,
        _fileName,
        'شهادة إتمام دورة ${widget.course?.title ?? ''} - EduAcademy',
      );
    } catch (_) {
      if (mounted) showSnack(context, 'تعذّرت المشاركة', error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = StorageService.instance;
    final name =
        s.userByEmail(widget.result.studentEmail)?.name ??
        (s.currentEmail == widget.result.studentEmail ? s.currentName : '');
    final course = widget.course;
    final result = widget.result;
    return Scaffold(
      appBar: AppBar(title: const Text('الشهادة')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            RepaintBoundary(
              key: _key,
              child: Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.orange, width: 3),
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
                        color: AppColors.text,
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
                    const SizedBox(height: 10),
                    Text(
                      'رقم الشهادة: ${result.id}',
                      style: const TextStyle(
                        fontSize: 10,
                        color: AppColors.textDim,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _busy ? null : _download,
                    icon: _busy
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.download),
                    label: Text(_busy ? 'جارٍ التجهيز...' : 'تحميل الشهادة'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _busy ? null : _share,
                    icon: const Icon(Icons.share),
                    label: const Text('مشاركة'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'تُحفظ الشهادة كصورة PNG في جهازك ويمكن مشاركتها مباشرة.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textDim, fontSize: 12),
            ),
          ],
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
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.text,
          ),
        ),
        Text(
          label,
          style: const TextStyle(color: AppColors.textDim, fontSize: 11),
        ),
      ],
    ),
  );
}
