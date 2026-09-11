// اختبارات محرك OTP + خدمة البريد + تدفق التسجيل مع تفعيل البريد (v1.3.0)
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:eduacademy/models/models.dart';
import 'package:eduacademy/screens/auth/register_screen.dart';
import 'package:eduacademy/screens/auth/verify_email_screen.dart';
import 'package:eduacademy/services/auth_service.dart';
import 'package:eduacademy/services/email/email_service.dart';
import 'package:eduacademy/services/otp_service.dart';
import 'package:eduacademy/services/storage_service.dart';
import 'package:eduacademy/theme.dart';

import 'fake_email_sender.dart';

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

  group('OtpService', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
      OtpService.now = DateTime.now;
    });

    test('generates 6 digits, verifies once, then invalid', () async {
      final code = await OtpService.issue(OtpPurpose.reset, 'A@Y.com');
      expect(code, matches(RegExp(r'^\d{6}$')));
      final t = await OtpService.current(OtpPurpose.reset);
      expect(t, isNotNull);
      expect(t!.email, 'a@y.com');
      expect(t.remaining.inMinutes, inInclusiveRange(9, 10));
      // البريد يُقارن بلا حساسية لحالة الأحرف
      expect(
        await OtpService.verify(OtpPurpose.reset, 'a@y.com', code),
        OtpVerifyResult.ok,
      );
      // استخدام واحد فقط
      expect(
        await OtpService.verify(OtpPurpose.reset, 'a@y.com', code),
        OtpVerifyResult.notIssued,
      );
    });

    test('wrong code counts attempts; 5th wrong => tooManyAttempts', () async {
      final code = await OtpService.issue(OtpPurpose.register, 'b@y.com');
      final wrong = code == '000000' ? '111111' : '000000';
      for (var i = 1; i < OtpService.maxAttempts; i++) {
        expect(
          await OtpService.verify(OtpPurpose.register, 'b@y.com', wrong),
          OtpVerifyResult.wrong,
        );
        expect((await OtpService.current(OtpPurpose.register))!.attempts, i);
      }
      expect(
        await OtpService.verify(OtpPurpose.register, 'b@y.com', wrong),
        OtpVerifyResult.tooManyAttempts,
      );
      // الرمز أُلغي حتى الصحيح لا يُقبل
      expect(
        await OtpService.verify(OtpPurpose.register, 'b@y.com', code),
        OtpVerifyResult.notIssued,
      );
    });

    test('expires after 10 minutes', () async {
      final base = DateTime(2030, 1, 1, 12);
      OtpService.now = () => base;
      final code = await OtpService.issue(OtpPurpose.reset, 'c@y.com');
      OtpService.now = () => base.add(const Duration(minutes: 9, seconds: 59));
      expect((await OtpService.current(OtpPurpose.reset))!.expired, isFalse);
      OtpService.now = () => base.add(const Duration(minutes: 10, seconds: 1));
      expect(
        await OtpService.verify(OtpPurpose.reset, 'c@y.com', code),
        OtpVerifyResult.expired,
      );
      expect(await OtpService.current(OtpPurpose.reset), isNull);
    });

    test('code for one email is not valid for another', () async {
      final code = await OtpService.issue(OtpPurpose.reset, 'd@y.com');
      expect(
        await OtpService.verify(OtpPurpose.reset, 'other@y.com', code),
        OtpVerifyResult.notIssued,
      );
    });

    test('register and reset codes are independent', () async {
      final r = await OtpService.issue(OtpPurpose.register, 'e@y.com');
      final p = await OtpService.issue(OtpPurpose.reset, 'e@y.com');
      expect(
        await OtpService.verify(OtpPurpose.register, 'e@y.com', p),
        r == p ? OtpVerifyResult.ok : OtpVerifyResult.wrong,
      );
    });

    test('resend cooldown 30s', () async {
      final base = DateTime(2030, 1, 1, 12);
      OtpService.now = () => base;
      await OtpService.issue(OtpPurpose.reset, 'f@y.com');
      expect(await OtpService.resendWaitSeconds(OtpPurpose.reset), 31);
      OtpService.now = () => base.add(const Duration(seconds: 31));
      expect(await OtpService.resendWaitSeconds(OtpPurpose.reset), 0);
    });

    test('code is stored hashed, never in plain text', () async {
      final code = await OtpService.issue(OtpPurpose.reset, 'g@y.com');
      final prefs = await SharedPreferences.getInstance();
      for (final k in prefs.getKeys()) {
        final v = prefs.get(k);
        if (v is String) expect(v.contains(code), isFalse, reason: k);
      }
    });
  });

  group('EmailService', () {
    test('sends OTP with subject/body containing code and 10 min', () async {
      final fake = FakeSender();
      EmailService.sender = fake;
      EmailService.debugCredentials = (user: 'u@x.com', pass: 'p');
      expect(EmailService.canSend, isTrue);
      final r = await EmailService.sendOtp(
        to: 'to@y.com',
        code: '123456',
        purpose: OtpPurpose.register,
        validFor: OtpService.ttl,
        recipientName: 'أحمد',
      );
      expect(r.sent, isTrue);
      expect(fake.sent.single.to, 'to@y.com');
      expect(fake.sent.single.subject, contains('123456'));
      expect(fake.sent.single.text, contains('123456'));
      expect(fake.sent.single.text, contains('10 دقائق'));
      expect(fake.sent.single.html, contains('1 2 3 4 5 6'));
      expect(fake.sent.single.html, contains('dir="rtl"'));
      EmailService.debugCredentials = null;
    });

    test('unsupported platform / no credentials => cannot send', () async {
      EmailService.sender = FakeSender(supported: false);
      EmailService.debugCredentials = (user: 'u', pass: 'p');
      expect(EmailService.canSend, isFalse);
      expect(EmailService.unavailableReason, contains('الويب'));
      EmailService.sender = FakeSender();
      EmailService.debugCredentials = (user: '', pass: '');
      expect(EmailService.canSend, isFalse);
      EmailService.debugCredentials = null;
    });
  });

  group('register + verify email flow', () {
    final s = StorageService.instance;
    late FakeSender fake;

    setUpAll(() async {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
      s.overridePath = inMemoryDatabasePath;
      await s.init();
    });

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      OtpService.now = DateTime.now;
      fake = FakeSender();
      EmailService.sender = fake;
      EmailService.debugCredentials = (user: 'u@x.com', pass: 'p');
    });

    tearDown(() => EmailService.debugCredentials = null);

    test(
      'register creates unverified user; unverified email can re-register',
      () async {
        expect(await s.register('س', 'reg@y.com', '123456'), isNull);
        expect(await s.isVerified('reg@y.com'), isFalse);
        expect(s.students.where((u) => u.email == 'reg@y.com'), isEmpty);
        // إعادة التسجيل بنفس البريد غير المفعّل تستبدل الحساب
        expect(await s.register('س2', 'reg@y.com', 'abcdef'), isNull);
        expect(await s.login('reg@y.com', 'abcdef'), isNotNull);
        await s.markVerified('reg@y.com');
        expect(await s.isVerified('reg@y.com'), isTrue);
        expect(s.students.where((u) => u.email == 'reg@y.com'), isNotEmpty);
        // بعد التفعيل يُرفض التسجيل بنفس البريد
        expect(
          await s.register('س3', 'reg@y.com', 'zzzzzz'),
          'البريد الإلكتروني مسجّل مسبقاً',
        );
      },
    );

    testWidgets(
      'VerifyEmailScreen: email sent, wrong then right code logs in',
      (t) async {
        t.view.physicalSize = const Size(390 * 2, 1200 * 2);
        t.view.devicePixelRatio = 2;
        addTearDown(t.view.resetPhysicalSize);
        await t.runAsync(
          () => s.register('ليلى', 'v@y.com', '123456', role: UserRole.teacher),
        );

        var verified = false;
        await t.pumpWidget(
          wrap(
            VerifyEmailScreen(
              email: 'v@y.com',
              name: 'ليلى',
              role: UserRole.teacher,
              onVerified: () => verified = true,
            ),
          ),
        );
        await t.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 400)),
        );
        await t.pump();
        await t.pump(const Duration(milliseconds: 300));

        // أُرسل بريد واحد يحتوي الرمز، ولا يُعرض الرمز داخل التطبيق
        expect(fake.sent, hasLength(1));
        expect(fake.sent.single.to, 'v@y.com');
        expect(
          find.text('أرسلنا رمز التحقق إلى بريدك الإلكتروني'),
          findsOneWidget,
        );
        expect(find.byIcon(Icons.copy), findsNothing);
        final code = RegExp(
          r'\d{6}',
        ).firstMatch(fake.sent.single.subject)!.group(0)!;

        // رمز خاطئ
        final wrong = code == '000000' ? '111111' : '000000';
        await t.runAsync(() async {
          await t.enterText(find.byType(TextFormField), wrong);
          await Future<void>.delayed(const Duration(milliseconds: 300));
        });
        await t.pump();
        await t.pump(const Duration(milliseconds: 300));
        expect(find.textContaining('الرمز غير صحيح'), findsOneWidget);
        expect(verified, isFalse);

        // رمز صحيح -> تفعيل + جلسة
        await t.runAsync(() async {
          await t.enterText(find.byType(TextFormField), code);
          await Future<void>.delayed(const Duration(milliseconds: 1500));
        });
        await t.pump();
        await t.pump(const Duration(seconds: 2));
        expect(verified, isTrue);
        await t.runAsync(() async {
          expect(await s.isVerified('v@y.com'), isTrue);
          expect(await AuthService.isLoggedIn(), isTrue);
          expect(await AuthService.isTeacher(), isTrue);
        });
      },
    );

    testWidgets('SMTP failure falls back to in-app code with copy button', (
      t,
    ) async {
      t.view.physicalSize = const Size(390 * 2, 1200 * 2);
      t.view.devicePixelRatio = 2;
      addTearDown(t.view.resetPhysicalSize);
      EmailService.sender = FakeSender(fail: true);
      await t.runAsync(() => s.register('ن', 'fb@y.com', '123456'));

      String? clipboard;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, (call) async {
            if (call.method == 'Clipboard.setData') {
              clipboard = (call.arguments as Map)['text'] as String;
            }
            return null;
          });

      await t.pumpWidget(
        wrap(
          VerifyEmailScreen(
            email: 'fb@y.com',
            name: 'ن',
            role: UserRole.student,
            onVerified: () {},
          ),
        ),
      );
      await t.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 400)),
      );
      await t.pump();
      await t.pump(const Duration(milliseconds: 300));
      expect(find.textContaining('لم يُرسل البريد'), findsOneWidget);
      expect(find.byIcon(Icons.copy), findsOneWidget);
      await t.tap(find.byIcon(Icons.copy));
      await t.pump();
      expect(clipboard, matches(RegExp(r'^\d{6}$')));
    });

    testWidgets('RegisterScreen navigates to VerifyEmailScreen', (t) async {
      t.view.physicalSize = const Size(390 * 2, 1400 * 2);
      t.view.devicePixelRatio = 2;
      addTearDown(t.view.resetPhysicalSize);
      await t.pumpWidget(wrap(const RegisterScreen()));
      await t.pumpAndSettle();
      final f = find.byType(TextFormField);
      await t.enterText(f.at(0), 'محمد علي');
      await t.enterText(f.at(1), 'new@y.com');
      await t.enterText(f.at(2), '123456');
      await t.enterText(f.at(3), '123456');
      await t.runAsync(() async {
        await t.ensureVisible(find.text('إنشاء الحساب'));
        await t.tap(find.text('إنشاء الحساب'));
        await Future<void>.delayed(const Duration(milliseconds: 600));
      });
      await t.pump();
      await t.pump(const Duration(milliseconds: 600));
      expect(find.text('تفعيل الحساب'), findsWidgets);
      expect(fake.sent.where((m) => m.to == 'new@y.com'), hasLength(1));
      await t.runAsync(() async {
        expect(await s.isVerified('new@y.com'), isFalse);
      });
    });
  });
}
