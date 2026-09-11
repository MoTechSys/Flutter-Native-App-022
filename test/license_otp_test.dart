// اختبار منطق الترخيص (بالشبكة الحقيقية) + تدفق OTP لنسيت كلمة المرور
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:eduacademy/screens/auth/forgot_password_screen.dart';
import 'package:eduacademy/services/email/email_service.dart';

import 'fake_email_sender.dart';
import 'package:eduacademy/services/license_service.dart';
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

  // عميل وهمي يحاكي GitHub API (المصدر الأساسي) والملف الخام
  http.Client fake({
    bool? active,
    String code = 'EDU-4H7K',
    bool deleted = false,
  }) => MockClient((req) async {
    if (deleted) return http.Response('Not Found', 404);
    final json = jsonEncode({'active': active, 'code': code, 'message': 'msg'});
    if (req.url.host == 'api.github.com') {
      return http.Response(
        jsonEncode({'content': base64Encode(utf8.encode(json))}),
        200,
        headers: {'content-type': 'application/json; charset=utf-8'},
      );
    }
    return http.Response(json, 200);
  });

  group('license logic', () {
    test('active=true opens immediately even if previously blocked', () async {
      SharedPreferences.setMockInitialValues({'lic_blocked': true});
      LicenseService.client = fake(active: true);
      final st = await LicenseService.check();
      expect(st.allowed, isTrue);
      expect(
        (await SharedPreferences.getInstance()).getBool('lic_blocked'),
        isFalse,
      );
    });

    test(
      'active=false asks for code; wrong rejected, right accepted & remembered',
      () async {
        SharedPreferences.setMockInitialValues({});
        LicenseService.client = fake(active: false);
        var st = await LicenseService.check();
        expect(st.allowed, isFalse);
        expect(st.codeAccepted, isTrue);
        expect(await LicenseService.activate('WRONG'), isFalse);
        expect(await LicenseService.activate('edu-4h7k'), isTrue);
        // إعادة التشغيل: ما زال false في الملف لكن الكود محفوظ => يفتح
        st = await LicenseService.check();
        expect(st.allowed, isTrue);
        // تغيير الكود في الملف => يقفل مجدداً
        LicenseService.client = fake(active: false, code: 'NEW-1');
        st = await LicenseService.check();
        expect(st.allowed, isFalse);
        // رجوع active=true => يفتح فوراً بدون كود
        LicenseService.client = fake(active: true, code: 'NEW-1');
        st = await LicenseService.check();
        expect(st.allowed, isTrue);
      },
    );

    test('file deleted (404) => locked, no code accepted', () async {
      SharedPreferences.setMockInitialValues({
        'lic_activated_code': 'EDU-4H7K',
      });
      LicenseService.client = fake(deleted: true);
      final st = await LicenseService.check();
      expect(st.allowed, isFalse);
      expect(st.codeAccepted, isFalse);
      expect(await LicenseService.activate('EDU-4H7K'), isFalse);
    });

    test('offline => last known state', () async {
      SharedPreferences.setMockInitialValues({'lic_blocked': false});
      LicenseService.client = MockClient(
        (_) async => throw Exception('no net'),
      );
      var st = await LicenseService.check();
      expect(st.allowed, isTrue);
      expect(st.offline, isTrue);
      SharedPreferences.setMockInitialValues({'lic_blocked': true});
      st = await LicenseService.check();
      expect(st.allowed, isFalse);
    });
  });

  group('forgot password OTP flow (email OTP, in-app fallback)', () {
    final s = StorageService.instance;
    setUpAll(() async {
      SharedPreferences.setMockInitialValues({});
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
      s.overridePath = inMemoryDatabasePath;
      await s.init();
      await s.register('طالب', 'otp@y.com', 'old123', verified: true);
      // في الاختبارات لا يوجد SMTP => يُعرض الرمز داخل التطبيق مع زر نسخ
      EmailService.sender = FakeSender(supported: false);
    });

    testWidgets('email -> OTP -> verify -> new password', (t) async {
      t.view.physicalSize = const Size(390 * 2, 1200 * 2);
      t.view.devicePixelRatio = 2;
      addTearDown(t.view.resetPhysicalSize);
      String? clipboard;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, (call) async {
            if (call.method == 'Clipboard.setData') {
              clipboard = (call.arguments as Map)['text'] as String;
            }
            if (call.method == 'Clipboard.getData') {
              return {'text': clipboard};
            }
            return null;
          });

      await t.pumpWidget(wrap(const ForgotPasswordScreen()));
      await t.pumpAndSettle();

      // 1) بريد غير مسجّل -> رسالة خطأ ويبقى في الخطوة 1
      await t.enterText(find.byType(TextFormField), 'none@y.com');
      await t.runAsync(() async {
        await t.tap(find.text('إرسال رمز التحقق'));
        await Future<void>.delayed(const Duration(milliseconds: 300));
      });
      await t.pump();
      expect(find.text('لا يوجد حساب بهذا البريد الإلكتروني'), findsOneWidget);

      // 2) بريد صحيح -> خطوة OTP (الرمز يُصدر ويُعرض لعدم توفر SMTP)
      await t.enterText(find.byType(TextFormField), 'otp@y.com');
      await t.runAsync(() async {
        await t.tap(find.text('إرسال رمز التحقق'));
        await Future<void>.delayed(const Duration(milliseconds: 500));
      });
      await t.pump();
      await t.pump(const Duration(milliseconds: 300));
      expect(find.text('رمز التحقق (OTP)'), findsOneWidget);
      expect(find.byIcon(Icons.copy), findsOneWidget);
      expect(find.textContaining('صالح لمدة'), findsOneWidget);

      // نسخ الرمز
      await t.tap(find.byIcon(Icons.copy));
      await t.pump();
      expect(clipboard, isNotNull);
      expect(clipboard!.length, 6);

      // 3) رمز خاطئ -> رسالة فشل ويبقى في الخطوة 2
      final otpField = find.byType(TextFormField);
      await t.runAsync(() async {
        await t.enterText(otpField, '000000'); // يتحقق تلقائياً عند 6 أرقام
        await Future<void>.delayed(const Duration(milliseconds: 300));
      });
      await t.pump();
      await t.pump(const Duration(milliseconds: 300));
      expect(find.textContaining('الرمز غير صحيح'), findsOneWidget);
      expect(find.text('رمز التحقق (OTP)'), findsOneWidget);

      // رمز صحيح (المنسوخ) -> خطوة كلمة المرور
      await t.runAsync(() async {
        await t.enterText(otpField, clipboard!);
        await Future<void>.delayed(const Duration(milliseconds: 400));
      });
      await t.pump();
      await t.pump(const Duration(milliseconds: 300));
      expect(find.text('كلمة مرور جديدة'), findsOneWidget);

      // 4) كلمة قصيرة/غير متطابقة -> validation
      final fields = find.byType(TextFormField);
      await t.enterText(fields.at(0), '123');
      await t.enterText(fields.at(1), '123');
      await t.ensureVisible(find.text('حفظ كلمة المرور'));
      await t.tap(find.text('حفظ كلمة المرور'));
      await t.pump();
      expect(find.textContaining('6 أحرف'), findsWidgets);

      await t.enterText(fields.at(0), 'new123');
      await t.enterText(fields.at(1), 'new124');
      await t.ensureVisible(find.text('حفظ كلمة المرور'));
      await t.tap(find.text('حفظ كلمة المرور'));
      await t.pump();
      expect(find.text('كلمتا المرور غير متطابقتين'), findsOneWidget);

      // صحيح -> يُغيّر ويعود
      await t.enterText(fields.at(1), 'new123');
      await t.runAsync(() async {
        await t.ensureVisible(find.text('حفظ كلمة المرور'));
        await t.tap(find.text('حفظ كلمة المرور'));
        await Future<void>.delayed(const Duration(milliseconds: 400));
      });
      await t.pump();
      await t.pump(const Duration(seconds: 3));

      // الدخول بالقديمة يفشل وبالجديدة ينجح
      await t.runAsync(() async {
        expect(await s.login('otp@y.com', 'old123'), isNull);
        expect(await s.login('otp@y.com', 'new123'), isNotNull);
      });
    });
  });
}
