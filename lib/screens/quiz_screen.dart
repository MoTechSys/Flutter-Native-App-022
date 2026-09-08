// ============================================================
// EduAcademy - حل الاختبار + النتيجة (StatefulWidget)
// ============================================================

import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/auth_service.dart';
import '../services/storage_service.dart';
import '../theme.dart';
import '../widgets/common.dart';

class QuizScreen extends StatefulWidget {
  final Course course;
  const QuizScreen({super.key, required this.course});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  late List<Question> _questions;
  int _index = 0;
  int? _selected;
  int _score = 0;
  bool _finished = false;

  @override
  void initState() {
    super.initState();
    _questions = StorageService.instance.questionsOf(widget.course.id);
  }

  Future<void> _next() async {
    if (_selected == null) {
      showSnack(context, 'اختر إجابة أولاً', error: true);
      return;
    }
    if (_selected == _questions[_index].correctIndex) _score++;
    if (_index + 1 < _questions.length) {
      setState(() {
        _index++;
        _selected = null;
      });
    } else {
      final email = await AuthService.currentEmail();
      await StorageService.instance.addResult(
        QuizResult(
          id: '',
          courseId: widget.course.id,
          studentEmail: email,
          score: _score,
          total: _questions.length,
          date: DateTime.now(),
        ),
      );
      if (mounted) setState(() => _finished = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = Color(widget.course.color);
    if (_finished) {
      return _ResultView(score: _score, total: _questions.length, color: color);
    }

    final q = _questions[_index];
    return Scaffold(
      appBar: AppBar(
        title: Text('اختبار: ${widget.course.title}'),
        backgroundColor: color,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'السؤال ${_index + 1} من ${_questions.length}',
                    style: const TextStyle(color: AppColors.textDim),
                  ),
                  const Spacer(),
                  Text(
                    'النقاط: $_score',
                    style: TextStyle(color: color, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: (_index + 1) / _questions.length,
                  minHeight: 6,
                  backgroundColor: AppColors.cardLight,
                  color: color,
                ),
              ),
              const SizedBox(height: 24),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Text(
                    q.text,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      height: 1.5,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.separated(
                  itemCount: q.options.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (_, i) {
                    final sel = _selected == i;
                    return InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => setState(() => _selected = i),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          color: sel
                              ? color.withValues(alpha: 0.12)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: sel ? color : const Color(0xFFD9DCE8),
                            width: sel ? 2 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              sel
                                  ? Icons.radio_button_checked
                                  : Icons.radio_button_off,
                              color: sel ? color : AppColors.textDim,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                q.options[i],
                                style: const TextStyle(fontSize: 15),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              ElevatedButton.icon(
                key: const Key('quiz_next'),
                style: ElevatedButton.styleFrom(backgroundColor: color),
                onPressed: _next,
                icon: Icon(
                  _index + 1 < _questions.length
                      ? Icons.arrow_back
                      : Icons.done_all,
                ),
                label: Text(
                  _index + 1 < _questions.length ? 'التالي' : 'إنهاء الاختبار',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ResultView extends StatelessWidget {
  final int score, total;
  final Color color;
  const _ResultView({
    required this.score,
    required this.total,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final pct = total == 0 ? 0 : (score / total * 100).round();
    final passed = pct >= 60;
    return Scaffold(
      appBar: AppBar(title: const Text('النتيجة'), backgroundColor: color),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 150,
                      height: 150,
                      child: CircularProgressIndicator(
                        value: pct / 100,
                        strokeWidth: 12,
                        backgroundColor: AppColors.cardLight,
                        color: passed ? AppColors.green : AppColors.red,
                      ),
                    ),
                    Text(
                      '$pct%',
                      style: const TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Icon(
                  passed ? Icons.emoji_events : Icons.sentiment_dissatisfied,
                  size: 48,
                  color: passed ? AppColors.orange : AppColors.red,
                ),
                const SizedBox(height: 8),
                Text(
                  passed ? 'مبروك! لقد نجحت' : 'لم تنجح هذه المرة',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'إجابات صحيحة: $score من $total',
                  style: const TextStyle(color: AppColors.textDim),
                ),
                if (passed)
                  const Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: Text(
                      'تم إصدار شهادتك – تجدها في قسم الشهادات',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.green),
                    ),
                  ),
                const SizedBox(height: 32),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: color),
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_forward),
                  label: const Text('العودة إلى الدورة'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
