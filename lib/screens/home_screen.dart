// ============================================================
// EduAcademy - الشاشة الرئيسية (لوحة الطالب / المعلم) + القائمة الجانبية
// ============================================================

import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/auth_service.dart';
import '../services/storage_service.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'about_screen.dart';
import 'certificates_screen.dart';
import 'course_details_screen.dart';
import 'courses_screen.dart';
import 'notes_screen.dart';
import 'stats_screen.dart';
import 'students_screen.dart';

class HomeScreen extends StatefulWidget {
  final VoidCallback onLogout;
  const HomeScreen({super.key, required this.onLogout});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _name = '';
  String _email = '';
  bool _teacher = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final n = await AuthService.currentName();
    final e = await AuthService.currentEmail();
    final t = await AuthService.isTeacher();
    if (mounted) {
      setState(() {
        _name = n;
        _email = e;
        _teacher = t;
      });
    }
  }

  Future<void> _logout() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('تسجيل الخروج'),
        content: const Text('هل تريد الخروج من حسابك؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('خروج', style: TextStyle(color: AppColors.red)),
          ),
        ],
      ),
    );
    if (ok == true) {
      await AuthService.logout();
      widget.onLogout();
    }
  }

  void _go(Widget page) {
    Navigator.pop(context); // إغلاق القائمة الجانبية
    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }

  @override
  Widget build(BuildContext context) {
    final s = StorageService.instance;
    return Scaffold(
      appBar: AppBar(title: const Text('EduAcademy')),
      drawer: _buildDrawer(),
      body: SafeArea(
        child: AnimatedBuilder(
          animation: s,
          builder: (context, _) {
            final courses = s.courses;
            final certs = s.certificatesOf(_email);
            final completed = s.completedCount(_email);
            final students = s.students.length;
            final attempts = s.results.length;
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // ترحيب مع صورة من Assets (Stack)
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Stack(
                    children: [
                      Image.asset(
                        'assets/images/hero.png',
                        height: 150,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              colors: [
                                Colors.black.withValues(alpha: 0.65),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 14,
                        right: 16,
                        left: 16,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'مرحباً، $_name',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              _teacher
                                  ? 'لوحة المعلم – إدارة المحتوى ومتابعة الطلاب'
                                  : 'واصل التعلّم اليوم',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: Colors.white70),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // إحصائيات (GridView)
                GridView.count(
                  crossAxisCount: 3,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 0.95,
                  children: _teacher
                      ? [
                          StatTile(
                            icon: Icons.menu_book,
                            color: AppColors.primary,
                            value: '${courses.length}',
                            label: 'دورة',
                          ),
                          StatTile(
                            icon: Icons.people,
                            color: AppColors.secondary,
                            value: '$students',
                            label: 'طالب',
                          ),
                          StatTile(
                            icon: Icons.quiz,
                            color: AppColors.orange,
                            value: '$attempts',
                            label: 'محاولة اختبار',
                          ),
                        ]
                      : [
                          StatTile(
                            icon: Icons.menu_book,
                            color: AppColors.primary,
                            value: '${courses.length}',
                            label: 'دورة',
                          ),
                          StatTile(
                            icon: Icons.check_circle,
                            color: AppColors.secondary,
                            value: '$completed',
                            label: 'درس مكتمل',
                          ),
                          StatTile(
                            icon: Icons.workspace_premium,
                            color: AppColors.orange,
                            value: '${certs.length}',
                            label: 'شهادة',
                          ),
                        ],
                ),
                if (_teacher) ...[
                  const SizedBox(height: 12),
                  // اختصارات المعلم
                  Row(
                    children: [
                      Expanded(
                        child: _QuickAction(
                          icon: Icons.people_outline,
                          label: 'الطلاب',
                          color: AppColors.secondary,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const StudentsScreen(),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _QuickAction(
                          icon: Icons.add_box_outlined,
                          label: 'دورة جديدة',
                          color: AppColors.primary,
                          onTap: () => showCourseForm(context),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _QuickAction(
                          icon: Icons.bar_chart,
                          label: 'الإحصائيات',
                          color: AppColors.orange,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  StatsScreen(email: _email, teacher: true),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'الدورات',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextButton(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const CoursesScreen(),
                        ),
                      ),
                      child: const Text('عرض الكل'),
                    ),
                  ],
                ),
                if (courses.isEmpty)
                  const SizedBox(
                    height: 160,
                    child: EmptyState(
                      icon: Icons.menu_book,
                      text: 'لا توجد دورات بعد',
                    ),
                  ),
                ...courses.take(4).map((c) => _CourseCard(course: c)),
              ],
            );
          },
        ),
      ),
    );
  }

  Drawer _buildDrawer() {
    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primary, Color(0xFF7C6CF0)],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const CircleAvatar(
                    radius: 28,
                    backgroundColor: Colors.white,
                    child: Icon(
                      Icons.person,
                      size: 32,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    _email,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      (_teacher ? UserRole.teacher : UserRole.student).label,
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  ListTile(
                    leading: const Icon(Icons.home_outlined),
                    title: const Text('الرئيسية'),
                    onTap: () => Navigator.pop(context),
                  ),
                  ListTile(
                    leading: const Icon(Icons.menu_book_outlined),
                    title: const Text('الدورات والدروس'),
                    onTap: () => _go(const CoursesScreen()),
                  ),
                  if (_teacher)
                    ListTile(
                      leading: const Icon(Icons.people_outline),
                      title: const Text('الطلاب'),
                      onTap: () => _go(const StudentsScreen()),
                    )
                  else ...[
                    ListTile(
                      leading: const Icon(Icons.sticky_note_2_outlined),
                      title: const Text('ملاحظاتي'),
                      onTap: () => _go(const NotesScreen()),
                    ),
                    ListTile(
                      leading: const Icon(Icons.workspace_premium_outlined),
                      title: const Text('شهاداتي'),
                      onTap: () => _go(CertificatesScreen(email: _email)),
                    ),
                  ],
                  ListTile(
                    leading: const Icon(Icons.bar_chart_outlined),
                    title: Text(
                      _teacher
                          ? 'أداء الطلاب والإحصائيات'
                          : 'نتائجي وإحصائياتي',
                    ),
                    onTap: () =>
                        _go(StatsScreen(email: _email, teacher: _teacher)),
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.info_outline),
                    title: const Text('حول التطبيق'),
                    onTap: () => _go(const AboutScreen()),
                  ),
                  ListTile(
                    leading: const Icon(Icons.logout, color: AppColors.red),
                    title: const Text(
                      'تسجيل الخروج',
                      style: TextStyle(color: AppColors.red),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      _logout();
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// زر اختصار في لوحة المعلم
class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => Material(
    color: color.withValues(alpha: 0.1),
    borderRadius: BorderRadius.circular(12),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Column(
          children: [
            Icon(icon, color: color),
            const SizedBox(height: 4),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

/// بطاقة دورة في الرئيسية
class _CourseCard extends StatelessWidget {
  final Course course;
  const _CourseCard({required this.course});

  @override
  Widget build(BuildContext context) {
    final s = StorageService.instance;
    final color = Color(course.color);
    final teacher = s.isTeacher;
    final progress = teacher ? 0.0 : s.progressOf(course.id);
    final count = s.lessonsOf(course.id).length;
    final qCount = s.questionsOf(course.id).length;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Card(
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => CourseDetailsScreen(courseId: course.id),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.play_lesson, color: color),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        course.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        teacher
                            ? '${course.instructor} • $count درس • $qCount سؤال'
                            : '${course.instructor} • $count درس',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.textDim,
                          fontSize: 12,
                        ),
                      ),
                      if (!teacher) ...[
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: progress,
                            minHeight: 6,
                            backgroundColor: AppColors.cardLight,
                            color: color,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                if (teacher)
                  const Icon(Icons.chevron_left, color: AppColors.textDim)
                else
                  Text(
                    '${(progress * 100).round()}%',
                    style: TextStyle(fontWeight: FontWeight.bold, color: color),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
