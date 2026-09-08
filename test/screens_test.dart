// اختبار الشاشات الفعلية ببيانات حقيقية عبر SQLite (في الذاكرة)
// على مقاس جوال ضيق 360x780 – يفشل إن وُجد أي Overflow.
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:eduacademy/models/models.dart';
import 'package:eduacademy/screens/about_screen.dart';
import 'package:eduacademy/screens/auth/forgot_password_screen.dart';
import 'package:eduacademy/screens/auth/login_screen.dart';
import 'package:eduacademy/screens/auth/register_screen.dart';
import 'package:eduacademy/screens/certificates_screen.dart';
import 'package:eduacademy/screens/course_details_screen.dart';
import 'package:eduacademy/screens/courses_screen.dart';
import 'package:eduacademy/screens/home_screen.dart';
import 'package:eduacademy/screens/lesson_screen.dart';
import 'package:eduacademy/screens/license_screen.dart';
import 'package:eduacademy/screens/notes_screen.dart';
import 'package:eduacademy/screens/quiz_screen.dart';
import 'package:eduacademy/screens/stats_screen.dart';
import 'package:eduacademy/services/storage_service.dart';
import 'package:eduacademy/theme.dart';

Widget wrap(Widget child) => MaterialApp(
  theme: buildTheme(),
  locale: const Locale('ar'),
  supportedLocales: const [Locale('ar')],
  localizationsDelegates: const [
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ],
  builder: (c, w) =>
      Directionality(textDirection: TextDirection.rtl, child: w!),
  home: child,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final s = StorageService.instance;

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({
      'session_email': 'x@y.com',
      'session_name': 'معتصم',
    });
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    s.overridePath = inMemoryDatabasePath;
    await s.init();
    // بيانات طويلة عمداً
    await s.addCourse(
      Course(
        id: 'long',
        title:
            'دورة متقدمة جداً في تصميم وتطوير تطبيقات الجوال متعددة المنصات باستخدام Flutter و Dart',
        instructor: 'الدكتور المهندس عبدالرحمن بن محمد الحجوري',
        category: 'تطوير تطبيقات الجوال المتقدمة',
        description:
            'وصف طويل جداً جداً يمتد على أكثر من سطر لاختبار التخطيط والالتفاف بشكل صحيح دون أي تجاوز.',
      ),
    );
    await s.addLesson(
      Lesson(
        id: '',
        courseId: 'long',
        title: 'درس بعنوان طويل جداً جداً لاختبار الاقتطاع في القائمة',
        durationMin: 999,
        content: 'محتوى',
      ),
    );
    await s.addNote(
      Note(
        id: '',
        courseId: 'long',
        title: 'ملاحظة بعنوان طويل جداً جداً جداً للاختبار',
        body: 'نص طويل ' * 30,
        date: DateTime.now(),
      ),
    );
    await s.addResult(
      QuizResult(
        id: '',
        courseId: 'long',
        studentEmail: 'a.very.long.email.address@university-domain.edu.sa',
        score: 7,
        total: 7,
        date: DateTime.now(),
      ),
    );
    await s.addResult(
      QuizResult(
        id: '',
        courseId: 'c1',
        studentEmail: 'x@y.com',
        score: 1,
        total: 3,
        date: DateTime.now(),
      ),
    );
  });

  setUp(() {
    TestWidgetsFlutterBinding.instance.platformDispatcher.views.first
      ..physicalSize = const Size(360 * 2, 780 * 2)
      ..devicePixelRatio = 2;
  });

  Future<void> check(WidgetTester t, Widget w, {bool scroll = true}) async {
    await t.pumpWidget(wrap(w));
    await t.pumpAndSettle();
    expect(t.takeException(), isNull);
    if (scroll && find.byType(ListView).evaluate().isNotEmpty) {
      await t.drag(find.byType(ListView).first, const Offset(0, -800));
      await t.pumpAndSettle();
      expect(t.takeException(), isNull);
    }
  }

  testWidgets(
    'login',
    (t) => check(t, LoginScreen(onLoggedIn: () {}), scroll: false),
  );
  testWidgets(
    'register',
    (t) => check(t, const RegisterScreen(), scroll: false),
  );
  testWidgets(
    'forgot',
    (t) => check(t, const ForgotPasswordScreen(), scroll: false),
  );
  testWidgets(
    'license',
    (t) => check(
      t,
      LicenseScreen(message: 'رسالة', onActivated: () {}),
      scroll: false,
    ),
  );
  testWidgets('about', (t) => check(t, const AboutScreen()));
  testWidgets('home', (t) => check(t, HomeScreen(onLogout: () {})));
  testWidgets('home drawer', (t) async {
    await t.pumpWidget(wrap(HomeScreen(onLogout: () {})));
    await t.pumpAndSettle();
    await t.tap(find.byIcon(Icons.menu));
    await t.pumpAndSettle();
    expect(t.takeException(), isNull);
    expect(find.text('الدورات والدروس'), findsOneWidget);
  });
  testWidgets(
    'courses grid',
    (t) => check(t, const CoursesScreen(), scroll: false),
  );
  testWidgets(
    'course details',
    (t) => check(t, const CourseDetailsScreen(courseId: 'long')),
  );
  testWidgets('lesson', (t) async {
    final l = s.lessonsOf('long').first;
    await check(t, LessonScreen(lesson: l, color: Colors.indigo));
  });
  testWidgets('quiz + result', (t) async {
    final c = s.courseById('c1')!;
    final qs = s.questionsOf('c1');
    await t.pumpWidget(wrap(QuizScreen(course: c)));
    await t.pumpAndSettle();
    expect(t.takeException(), isNull);
    for (var i = 0; i < qs.length; i++) {
      expect(
        find.text('السؤال ${i + 1} من ${qs.length}'),
        findsOneWidget,
        reason: 'question index $i',
      );
      await t.tap(find.text(qs[i].options[qs[i].correctIndex]).first);
      await t.pump();
      await t.runAsync(() async {
        await t.tap(find.byKey(const Key('quiz_next')));
        await Future<void>.delayed(const Duration(milliseconds: 400));
      });
      await t.pump();
      expect(t.takeException(), isNull);
    }
    // انتظار حفظ النتيجة في قاعدة البيانات ثم ظهور شاشة النتيجة
    expect(t.takeException(), isNull);
    expect(find.text('النتيجة'), findsOneWidget);
    expect(
      s.results.where((r) => r.courseId == 'c1').length,
      greaterThanOrEqualTo(2),
    );
  });
  testWidgets('notes', (t) => check(t, const NotesScreen()));
  testWidgets(
    'certificates',
    (t) => check(
      t,
      const CertificatesScreen(
        email: 'a.very.long.email.address@university-domain.edu.sa',
      ),
    ),
  );
  testWidgets('certificate view', (t) async {
    final r = s.results.first;
    await check(
      t,
      CertificateView(result: r, course: s.courseById(r.courseId)),
    );
  });
  testWidgets(
    'stats teacher',
    (t) => check(t, const StatsScreen(email: '', teacher: true)),
  );
  testWidgets(
    'stats student',
    (t) => check(t, const StatsScreen(email: 'x@y.com', teacher: false)),
  );
}
