// ============================================================
// EduAcademy - نماذج البيانات
// ============================================================

/// دور المستخدم
enum UserRole { student, teacher }

extension UserRoleX on UserRole {
  String get label => this == UserRole.student ? 'طالب' : 'معلم';
}

/// دورة تعليمية
class Course {
  String id;
  String title;
  String instructor;
  String category;
  String description;
  int color; // لون البطاقة (ARGB)

  Course({
    required this.id,
    required this.title,
    required this.instructor,
    required this.category,
    this.description = '',
    this.color = 0xFF5B4BDB,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'title': title,
    'instructor': instructor,
    'category': category,
    'description': description,
    'color': color,
  };

  factory Course.fromMap(Map m) => Course(
    id: m['id'],
    title: m['title'] ?? '',
    instructor: m['instructor'] ?? '',
    category: m['category'] ?? '',
    description: m['description'] ?? '',
    color: m['color'] ?? 0xFF5B4BDB,
  );
}

/// مستخدم (طالب أو معلم)
class AppUser {
  int id;
  String name;
  String email;
  UserRole role;

  AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
  });

  factory AppUser.fromMap(Map m) => AppUser(
    id: m['id'] ?? 0,
    name: m['name'] ?? '',
    email: m['email'] ?? '',
    role: (m['role'] ?? 0) == 1 ? UserRole.teacher : UserRole.student,
  );
}

/// درس داخل دورة (الإكمال يُحفظ لكل طالب في جدول progress)
class Lesson {
  String id;
  String courseId;
  String title;
  int durationMin;
  String content;

  Lesson({
    required this.id,
    required this.courseId,
    required this.title,
    required this.durationMin,
    this.content = '',
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'courseId': courseId,
    'title': title,
    'durationMin': durationMin,
    'content': content,
  };

  factory Lesson.fromMap(Map m) => Lesson(
    id: m['id'],
    courseId: m['courseId'],
    title: m['title'] ?? '',
    durationMin: m['durationMin'] ?? 0,
    content: m['content'] ?? '',
  );
}

/// ملاحظة الطالب (خاصة بصاحبها)
class Note {
  String id;
  String courseId;
  String studentEmail;
  String title;
  String body;
  DateTime date;

  Note({
    required this.id,
    required this.courseId,
    required this.title,
    required this.body,
    required this.date,
    this.studentEmail = '',
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'courseId': courseId,
    'studentEmail': studentEmail,
    'title': title,
    'body': body,
    'date': date.toIso8601String(),
  };

  factory Note.fromMap(Map m) => Note(
    id: m['id'],
    courseId: m['courseId'],
    studentEmail: m['studentEmail'] ?? '',
    title: m['title'] ?? '',
    body: m['body'] ?? '',
    date: DateTime.parse(m['date']),
  );
}

/// سؤال اختبار (اختيار من متعدد)
class Question {
  String id;
  String courseId;
  String text;
  List<String> options;
  int correctIndex;

  Question({
    required this.id,
    required this.courseId,
    required this.text,
    required this.options,
    required this.correctIndex,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'courseId': courseId,
    'text': text,
    'options': options.join('|'),
    'correctIndex': correctIndex,
  };

  factory Question.fromMap(Map m) => Question(
    id: m['id'],
    courseId: m['courseId'],
    text: m['text'] ?? '',
    options: (m['options'] ?? '').toString().split('|'),
    correctIndex: m['correctIndex'] ?? 0,
  );
}

/// نتيجة اختبار (تمثل أداء الطالب)
class QuizResult {
  String id;
  String courseId;
  String studentEmail;
  int score;
  int total;
  DateTime date;

  QuizResult({
    required this.id,
    required this.courseId,
    required this.studentEmail,
    required this.score,
    required this.total,
    required this.date,
  });

  double get percent => total == 0 ? 0 : score / total * 100;
  bool get passed => percent >= 60;

  Map<String, dynamic> toMap() => {
    'id': id,
    'courseId': courseId,
    'studentEmail': studentEmail,
    'score': score,
    'total': total,
    'date': date.toIso8601String(),
  };

  factory QuizResult.fromMap(Map m) => QuizResult(
    id: m['id'],
    courseId: m['courseId'],
    studentEmail: m['studentEmail'] ?? '',
    score: m['score'] ?? 0,
    total: m['total'] ?? 0,
    date: DateTime.parse(m['date']),
  );
}
