// ============================================================
// EduAcademy - قاعدة البيانات المحلية (SQLite) + عمليات CRUD
//
// الجداول: users, courses, lessons, notes, questions, results, progress
// - progress: إكمال الدروس لكل طالب على حدة (studentEmail + lessonId)
// - notes: خاصة بصاحبها (studentEmail)
// ============================================================

import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import '../models/models.dart';
import 'password_hasher.dart';

class StorageService extends ChangeNotifier {
  static final StorageService instance = StorageService._();
  StorageService._();

  late Database _db;

  List<AppUser> _users = [];
  List<Course> _courses = [];
  List<Lesson> _lessons = [];
  List<Note> _notes = [];
  List<Question> _questions = [];
  List<QuizResult> _results = [];

  /// (studentEmail, lessonId) للدروس المكتملة
  final Set<String> _progress = {};
  static String _pKey(String email, String lessonId) => '$email|$lessonId';

  /// المستخدم الحالي (يُضبط عند الدخول ويُستخدم لتصفية البيانات الخاصة)
  String currentEmail = '';
  String currentName = '';
  bool isTeacher = false;

  /// مسار مخصص لقاعدة البيانات (يُستخدم في الاختبارات فقط)
  String? overridePath;

  Future<void> init() async {
    if (kIsWeb) databaseFactory = databaseFactoryFfiWeb;
    final path = overridePath ?? '${await getDatabasesPath()}/eduacademy.db';
    _db = await openDatabase(
      path,
      version: 2,
      onCreate: (db, v) async {
        await db.execute(
          'CREATE TABLE users(id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT, email TEXT UNIQUE, password TEXT, role INTEGER)',
        );
        await db.execute(
          'CREATE TABLE courses(id TEXT PRIMARY KEY, title TEXT, instructor TEXT, category TEXT, description TEXT, color INTEGER)',
        );
        await db.execute(
          'CREATE TABLE lessons(id TEXT PRIMARY KEY, courseId TEXT, title TEXT, durationMin INTEGER, content TEXT)',
        );
        await db.execute(
          'CREATE TABLE notes(id TEXT PRIMARY KEY, courseId TEXT, studentEmail TEXT, title TEXT, body TEXT, date TEXT)',
        );
        await db.execute(
          'CREATE TABLE questions(id TEXT PRIMARY KEY, courseId TEXT, text TEXT, options TEXT, correctIndex INTEGER)',
        );
        await db.execute(
          'CREATE TABLE results(id TEXT PRIMARY KEY, courseId TEXT, studentEmail TEXT, score INTEGER, total INTEGER, date TEXT)',
        );
        await _createProgress(db);
        await _seed(db);
      },
      onUpgrade: (db, oldV, newV) async {
        // الترقية من الإصدار 1: فصل التقدّم والملاحظات لكل طالب
        if (oldV < 2) {
          await _createProgress(db);
          await db.execute('ALTER TABLE notes ADD COLUMN studentEmail TEXT');
          await db.execute("UPDATE notes SET studentEmail = ''");
        }
      },
    );
    await _reload();
  }

  Future<void> _createProgress(Database db) => db.execute(
    'CREATE TABLE IF NOT EXISTS progress(studentEmail TEXT, lessonId TEXT, date TEXT, PRIMARY KEY(studentEmail, lessonId))',
  );

  /// بيانات أولية حتى لا يبدأ التطبيق فارغاً
  Future<void> _seed(Database db) async {
    final c1 = Course(
      id: 'c1',
      title: 'أساسيات البرمجة بلغة Dart',
      instructor: 'د. أحمد سالم',
      category: 'برمجة',
      description: 'مقدمة شاملة في لغة Dart: المتغيرات، الدوال، الكائنات.',
      color: 0xFF5B4BDB,
    );
    final c2 = Course(
      id: 'c2',
      title: 'تطوير التطبيقات بـ Flutter',
      instructor: 'أ. سارة محمد',
      category: 'تطوير تطبيقات',
      description: 'بناء واجهات تفاعلية وتطبيقات متعددة المنصات.',
      color: 0xFF0EA5E9,
    );
    final c3 = Course(
      id: 'c3',
      title: 'قواعد البيانات SQL',
      instructor: 'د. خالد يوسف',
      category: 'قواعد بيانات',
      description: 'تصميم الجداول وكتابة الاستعلامات.',
      color: 0xFF1FA97A,
    );
    for (final c in [c1, c2, c3]) {
      await db.insert('courses', c.toMap());
    }
    final lessons = [
      Lesson(
        id: 'l1',
        courseId: 'c1',
        title: 'المتغيرات وأنواع البيانات',
        durationMin: 25,
        content:
            'شرح أنواع البيانات الأساسية في Dart وكيفية تعريف المتغيرات باستخدام var و final و const.',
      ),
      Lesson(
        id: 'l2',
        courseId: 'c1',
        title: 'الدوال والمعاملات',
        durationMin: 30,
        content:
            'كيفية كتابة الدوال، المعاملات الاختيارية والمسماة، والدوال السهمية.',
      ),
      Lesson(
        id: 'l3',
        courseId: 'c1',
        title: 'البرمجة الكائنية',
        durationMin: 40,
        content: 'الكلاسات، الوراثة، الواجهات، والـ Mixins.',
      ),
      Lesson(
        id: 'l4',
        courseId: 'c2',
        title: 'مقدمة إلى Widgets',
        durationMin: 35,
        content: 'StatelessWidget و StatefulWidget وشجرة العناصر.',
      ),
      Lesson(
        id: 'l5',
        courseId: 'c2',
        title: 'التخطيط: Row و Column',
        durationMin: 30,
        content: 'بناء الواجهات باستخدام Row، Column، Expanded، Stack.',
      ),
      Lesson(
        id: 'l6',
        courseId: 'c3',
        title: 'إنشاء الجداول',
        durationMin: 20,
        content: 'CREATE TABLE، الأنواع، المفاتيح الأساسية.',
      ),
      Lesson(
        id: 'l7',
        courseId: 'c3',
        title: 'الاستعلامات SELECT',
        durationMin: 30,
        content: 'SELECT، WHERE، ORDER BY، JOIN.',
      ),
    ];
    for (final l in lessons) {
      await db.insert('lessons', l.toMap());
    }
    final qs = [
      Question(
        id: 'q1',
        courseId: 'c1',
        text: 'أي كلمة تُستخدم لتعريف ثابت وقت الترجمة في Dart؟',
        options: ['var', 'final', 'const', 'let'],
        correctIndex: 2,
      ),
      Question(
        id: 'q2',
        courseId: 'c1',
        text: 'ما نوع البيانات للقيمة 3.14؟',
        options: ['int', 'double', 'String', 'bool'],
        correctIndex: 1,
      ),
      Question(
        id: 'q3',
        courseId: 'c1',
        text: 'ما الكلمة المستخدمة للوراثة؟',
        options: ['implements', 'extends', 'with', 'inherits'],
        correctIndex: 1,
      ),
      Question(
        id: 'q4',
        courseId: 'c2',
        text: 'أي Widget يُستخدم لترتيب العناصر أفقياً؟',
        options: ['Column', 'Row', 'Stack', 'ListView'],
        correctIndex: 1,
      ),
      Question(
        id: 'q5',
        courseId: 'c2',
        text: 'أي Widget تتغير حالته أثناء التشغيل؟',
        options: ['StatelessWidget', 'StatefulWidget', 'Text', 'Icon'],
        correctIndex: 1,
      ),
      Question(
        id: 'q6',
        courseId: 'c3',
        text: 'ما الأمر المستخدم لجلب البيانات؟',
        options: ['INSERT', 'UPDATE', 'SELECT', 'DELETE'],
        correctIndex: 2,
      ),
      Question(
        id: 'q7',
        courseId: 'c3',
        text: 'ما الأمر المستخدم لتصفية النتائج؟',
        options: ['ORDER BY', 'WHERE', 'GROUP BY', 'JOIN'],
        correctIndex: 1,
      ),
    ];
    for (final q in qs) {
      await db.insert('questions', q.toMap());
    }
  }

  Future<void> _reload() async {
    _users = (await _db.query(
      'users',
      columns: ['id', 'name', 'email', 'role'],
    )).map((e) => AppUser.fromMap(e)).toList();
    _courses = (await _db.query(
      'courses',
    )).map((e) => Course.fromMap(e)).toList();
    _lessons = (await _db.query(
      'lessons',
    )).map((e) => Lesson.fromMap(e)).toList();
    _notes = (await _db.query('notes')).map((e) => Note.fromMap(e)).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    _questions = (await _db.query(
      'questions',
    )).map((e) => Question.fromMap(e)).toList();
    _results =
        (await _db.query('results')).map((e) => QuizResult.fromMap(e)).toList()
          ..sort((a, b) => b.date.compareTo(a.date));
    _progress
      ..clear()
      ..addAll(
        (await _db.query('progress')).map(
          (e) => _pKey(e['studentEmail'] as String, e['lessonId'] as String),
        ),
      );
    notifyListeners();
  }

  String _newId() => DateTime.now().microsecondsSinceEpoch.toString();

  // ================= الجلسة =================
  void setSession(String email, String name, bool teacher) {
    currentEmail = email;
    currentName = name;
    isTeacher = teacher;
    notifyListeners();
  }

  void clearSession() => setSession('', '', false);

  // ================= المستخدمون =================
  Future<String?> register(
    String name,
    String email,
    String password, {
    UserRole role = UserRole.student,
  }) async {
    final exists = await _db.query(
      'users',
      where: 'email = ?',
      whereArgs: [email.toLowerCase()],
    );
    if (exists.isNotEmpty) return 'البريد الإلكتروني مسجّل مسبقاً';
    await _db.insert('users', {
      'name': name,
      'email': email.toLowerCase(),
      'password': PasswordHasher.hash(password),
      'role': role.index,
    });
    await _reload();
    return null;
  }

  Future<Map<String, dynamic>?> login(String email, String password) async {
    final rows = await _db.query(
      'users',
      where: 'email = ?',
      whereArgs: [email.toLowerCase()],
    );
    if (rows.isEmpty) return null;
    return PasswordHasher.verify(password, rows.first['password'] as String)
        ? rows.first
        : null;
  }

  Future<bool> emailExists(String email) async => (await _db.query(
    'users',
    where: 'email = ?',
    whereArgs: [email.toLowerCase()],
  )).isNotEmpty;

  Future<void> resetPassword(String email, String newPassword) async {
    await _db.update(
      'users',
      {'password': PasswordHasher.hash(newPassword)},
      where: 'email = ?',
      whereArgs: [email.toLowerCase()],
    );
  }

  /// كل الطلاب (للمعلم)
  List<AppUser> get students =>
      _users.where((u) => u.role == UserRole.student).toList();
  AppUser? userByEmail(String email) =>
      _users.where((u) => u.email == email.toLowerCase()).firstOrNull;

  /// حذف حساب طالب مع كل بياناته (للمعلم)
  Future<void> deleteStudent(String email) async {
    final e = email.toLowerCase();
    await _db.delete('users', where: 'email = ?', whereArgs: [e]);
    await _db.delete('notes', where: 'studentEmail = ?', whereArgs: [e]);
    await _db.delete('results', where: 'studentEmail = ?', whereArgs: [e]);
    await _db.delete('progress', where: 'studentEmail = ?', whereArgs: [e]);
    await _reload();
  }

  // ================= الدورات (CRUD) =================
  List<Course> get courses => _courses;
  Course? courseById(String id) =>
      _courses.where((c) => c.id == id).firstOrNull;

  Future<void> addCourse(Course c) async {
    c.id = c.id.isEmpty ? _newId() : c.id;
    await _db.insert('courses', c.toMap());
    await _reload();
  }

  Future<void> updateCourse(Course c) async {
    await _db.update('courses', c.toMap(), where: 'id = ?', whereArgs: [c.id]);
    await _reload();
  }

  Future<void> deleteCourse(String id) async {
    final lessonIds = lessonsOf(id).map((l) => l.id).toList();
    await _db.delete('courses', where: 'id = ?', whereArgs: [id]);
    await _db.delete('lessons', where: 'courseId = ?', whereArgs: [id]);
    await _db.delete('notes', where: 'courseId = ?', whereArgs: [id]);
    await _db.delete('questions', where: 'courseId = ?', whereArgs: [id]);
    await _db.delete('results', where: 'courseId = ?', whereArgs: [id]);
    for (final lid in lessonIds) {
      await _db.delete('progress', where: 'lessonId = ?', whereArgs: [lid]);
    }
    await _reload();
  }

  // ================= الدروس (CRUD) =================
  List<Lesson> lessonsOf(String courseId) =>
      _lessons.where((l) => l.courseId == courseId).toList();
  List<Lesson> get lessons => _lessons;

  Future<void> addLesson(Lesson l) async {
    l.id = l.id.isEmpty ? _newId() : l.id;
    await _db.insert('lessons', l.toMap());
    await _reload();
  }

  Future<void> updateLesson(Lesson l) async {
    await _db.update('lessons', l.toMap(), where: 'id = ?', whereArgs: [l.id]);
    await _reload();
  }

  Future<void> deleteLesson(String id) async {
    await _db.delete('lessons', where: 'id = ?', whereArgs: [id]);
    await _db.delete('progress', where: 'lessonId = ?', whereArgs: [id]);
    await _reload();
  }

  // ================= التقدّم (لكل طالب) =================
  bool isCompleted(String lessonId, [String? email]) =>
      _progress.contains(_pKey(email ?? currentEmail, lessonId));

  int completedCount([String? email]) {
    final e = email ?? currentEmail;
    return _lessons.where((l) => isCompleted(l.id, e)).length;
  }

  double progressOf(String courseId, [String? email]) {
    final l = lessonsOf(courseId);
    if (l.isEmpty) return 0;
    final e = email ?? currentEmail;
    return l.where((x) => isCompleted(x.id, e)).length / l.length;
  }

  Future<void> toggleLesson(Lesson l, [String? email]) async {
    final e = email ?? currentEmail;
    if (isCompleted(l.id, e)) {
      await _db.delete(
        'progress',
        where: 'studentEmail = ? AND lessonId = ?',
        whereArgs: [e, l.id],
      );
    } else {
      await _db.insert('progress', {
        'studentEmail': e,
        'lessonId': l.id,
        'date': DateTime.now().toIso8601String(),
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await _reload();
  }

  // ================= الملاحظات (CRUD) =================
  List<Note> get notes => _notes;
  List<Note> notesOf(String email) =>
      _notes.where((n) => n.studentEmail == email).toList();
  List<Note> get myNotes => notesOf(currentEmail);

  Future<void> addNote(Note n) async {
    n.id = n.id.isEmpty ? _newId() : n.id;
    if (n.studentEmail.isEmpty) n.studentEmail = currentEmail;
    await _db.insert('notes', n.toMap());
    await _reload();
  }

  Future<void> updateNote(Note n) async {
    await _db.update('notes', n.toMap(), where: 'id = ?', whereArgs: [n.id]);
    await _reload();
  }

  Future<void> deleteNote(String id) async {
    await _db.delete('notes', where: 'id = ?', whereArgs: [id]);
    await _reload();
  }

  // ================= الأسئلة (CRUD) =================
  List<Question> get questions => _questions;
  List<Question> questionsOf(String courseId) =>
      _questions.where((q) => q.courseId == courseId).toList();

  Future<void> addQuestion(Question q) async {
    q.id = q.id.isEmpty ? _newId() : q.id;
    await _db.insert('questions', q.toMap());
    await _reload();
  }

  Future<void> updateQuestion(Question q) async {
    await _db.update(
      'questions',
      q.toMap(),
      where: 'id = ?',
      whereArgs: [q.id],
    );
    await _reload();
  }

  Future<void> deleteQuestion(String id) async {
    await _db.delete('questions', where: 'id = ?', whereArgs: [id]);
    await _reload();
  }

  // ================= النتائج والشهادات =================
  List<QuizResult> get results => _results;
  List<QuizResult> resultsOf(String email) =>
      _results.where((r) => r.studentEmail == email).toList();

  /// الشهادات = النتائج الناجحة (>= 60%)
  List<QuizResult> certificatesOf(String email) =>
      resultsOf(email).where((r) => r.passed).toList();

  Future<void> addResult(QuizResult r) async {
    r.id = r.id.isEmpty ? _newId() : r.id;
    await _db.insert('results', r.toMap());
    await _reload();
  }

  Future<void> deleteResult(String id) async {
    await _db.delete('results', where: 'id = ?', whereArgs: [id]);
    await _reload();
  }

  /// متوسط النتائج (للإحصائيات)
  double get avgScore => _results.isEmpty
      ? 0
      : _results.map((r) => r.percent).reduce((a, b) => a + b) /
            _results.length;

  /// متوسط درجات طالب معيّن
  double avgOf(String email) {
    final r = resultsOf(email);
    return r.isEmpty
        ? 0
        : r.map((x) => x.percent).reduce((a, b) => a + b) / r.length;
  }
}
