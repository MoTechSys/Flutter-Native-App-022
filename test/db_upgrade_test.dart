// ترقية قاعدة البيانات v2 -> v3: الحسابات القديمة تبقى تعمل وتُعدّ مفعّلة
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:eduacademy/services/storage_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('existing v2 users survive upgrade to v3 as verified', () async {
    SharedPreferences.setMockInitialValues({});
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    final path = '${await databaseFactory.getDatabasesPath()}/upgrade_test.db';
    await databaseFactory.deleteDatabase(path);

    // قاعدة بيانات بصيغة الإصدار 2 (بدون عمود verified)
    final old = await databaseFactory.openDatabase(
      path,
      options: OpenDatabaseOptions(
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
          await db.execute(
            'CREATE TABLE progress(studentEmail TEXT, lessonId TEXT, date TEXT, PRIMARY KEY(studentEmail, lessonId))',
          );
          await db.insert('users', {
            'name': 'قديم',
            'email': 'old@y.com',
            // نفس صيغة PasswordHasher (يُتحقق منها عبر login أدناه)
            'password': '5000\$c2FsdHNhbHRzYWx0c2FsdA==\$x',
            'role': 0,
          });
        },
      ),
    );
    await old.close();

    final s = StorageService.instance;
    s.overridePath = path;
    await s.init();

    // المستخدم القديم موجود ويُعدّ مفعّلاً ويظهر في قائمة الطلاب
    expect(await s.isVerified('old@y.com'), isTrue);
    expect(s.students.where((u) => u.email == 'old@y.com'), isNotEmpty);
    // إعادة التسجيل بنفس البريد مرفوضة (لأنه مفعّل)
    expect(
      await s.register('x', 'old@y.com', '123456'),
      'البريد الإلكتروني مسجّل مسبقاً',
    );
    // تغيير كلمة المرور يعمل بعد الترقية
    await s.resetPassword('old@y.com', 'new123');
    expect(await s.login('old@y.com', 'new123'), isNotNull);
    await databaseFactory.deleteDatabase(path);
  });
}
