# EduAcademy – سجل التغييرات والتوثيق الفني (v1.2.0 → v1.3.0)

> مستودع: `MoTechSys/Flutter-Native-App-022` – حزمة: `com.eduacademy.app`
> الإصدار: **1.3.0 (versionCode 6)** — تحديث فوق 1.2.0 (build 5) بنفس مفتاح التوقيع
> ملف التحكم عن بُعد: `license.json` في جذر المستودع (لم يتغيّر)

---

## ملخص التحديث

| المجال | قبل (1.2.0) | بعد (1.3.0) |
|---|---|---|
| إنشاء حساب | يُنشأ ويُطلب تسجيل الدخول فوراً | يُنشأ **غير مفعّل** → يُرسل رمز تحقق إلى البريد → إدخاله يفعّل الحساب ويسجّل الدخول مباشرة |
| نسيت كلمة المرور | الرمز يُعرض داخل التطبيق فقط (5 دقائق) | الرمز **يُرسل إلى بريد المستخدم** (10 دقائق)؛ الرمز الخاطئ = رسالة فشل ويبقى في نفس الخطوة؛ الصحيح = واجهة كلمة المرور الجديدة |
| صلاحية الرمز | 5 دقائق، يُفقد عند الخروج من الشاشة | **10 دقائق**، محفوظ مُجزّأً (SHA-256+salt) فيبقى صالحاً بعد الخروج من التطبيق والرجوع |
| المحاولات | 5 | 5 (يُلغى الرمز بعدها) + مهلة إعادة إرسال 30 ثانية |
| الكيبورد بعد الرجوع للتطبيق | قد لا يظهر (خلل Android) | إصلاح `KeyboardResumeFix` على شاشات الدخول/التسجيل/التفعيل/الاستعادة |
| الويب / بلا SMTP | — | **تراجع تلقائي**: الرمز يُعرض داخل التطبيق مع زر نسخ (التدفق لا يتعطل أبداً) |
| قاعدة البيانات | v2 | **v3**: عمود `users.verified` (الحسابات القديمة تُعدّ مفعّلة تلقائياً) |
| الاختبارات | 24 | **38** (كلها ناجحة) |

---

## 1) إرسال البريد (SMTP)

**الملفات:** `lib/config/mail_config.dart`, `lib/services/email/*`

- الحزمة: `mailer ^7.2.0` (Dart خالص، متوافقة مع Flutter 3.35.4 / Dart 3.9.2).
- **Conditional imports**: `email_sender_io.dart` (Android/Desktop: SMTP حقيقي) و`email_sender_web.dart` (الويب: غير مدعوم → تراجع). `dart:io` لا يعمل على الويب لذا لا يُستورد فيه.
- الاتصال: `smtp.gmail.com:587` STARTTLS (أو 465 SSL إن ضُبط `SMTP_PORT=465`)، مهلة 20 ثانية.
- كلمة مرور تطبيق Google تأتي بمسافات (`xxxx xxxx xxxx xxxx`)؛ `MailConfig.normalizedPass` يزيلها.
- **لا تُكتب البيانات في الكود** (المستودع عام). تُمرَّر وقت البناء:
  ```bash
  flutter build apk --release --dart-define=SMTP_USER=... --dart-define=SMTP_PASS=...
  ```
  أو عبر `android/smtp.properties` (مُتجاهَل في git) + `tool/build_release.sh`.
- بدون بيانات → `EmailService.canSend == false` → يُعرض الرمز داخل التطبيق.
- الرسالة: نص عادي + HTML بالعربية (RTL)، تحمل الرمز في العنوان والجسم، تذكر المدة (10 دقائق) و"يُستخدم مرة واحدة" وتنبيه "إن لم تطلب الرمز فتجاهل الرسالة".
- الأخطاء تُترجم لرسائل عربية واضحة: مهلة / مصادقة مرفوضة / لا شبكة / خطأ SMTP.

**التحقق الحي:** تم اختبار الدخول والإرسال عبر Gmail SMTP (587) من بيئة التطوير بنجاح قبل الاعتماد.

## 2) محرك OTP الجديد

**الملف:** `lib/services/otp_service.dart` (استُبدل المنطق الذي كان داخل شاشة الاستعادة)

| الخاصية | القيمة | المرجع |
|---|---|---|
| طول الرمز | 6 أرقام، `Random.secure()` | NIST 800-63B §5.1.4 |
| الصلاحية | **10 دقائق** | طلب صاحب المشروع |
| الاستخدام | مرة واحدة (يُلغى عند النجاح) | OWASP ASVS 2.8 |
| المحاولات | 5 ثم يُلغى الرمز | حماية من التخمين |
| إعادة الإرسال | بعد 30 ثانية | منع الإغراق |
| التخزين | SHA-256(salt:code) في SharedPreferences — **لا يُحفظ الرمز نصاً** | |
| المقارنة | زمن ثابت (constant-time) | |
| العزل | رمز التسجيل ≠ رمز الاستعادة (`OtpPurpose`)، ومرتبط بالبريد | |

يبقى الرمز صالحاً إذا خرج المستخدم من التطبيق (أو أُغلق) وعاد خلال 10 دقائق؛ `OtpPanel` يستعيده بدل إصدار رمز جديد.

## 3) تفعيل الحساب بعد التسجيل

**الملفات:** `lib/screens/auth/register_screen.dart`, `lib/screens/auth/verify_email_screen.dart`, `lib/screens/auth/login_screen.dart`, `lib/services/storage_service.dart`

التدفق:
1. المستخدم يملأ نموذج التسجيل (الاسم/البريد/كلمة المرور/الدور).
2. `register()` يُنشئ الحساب بـ `verified = 0`.
   - إن كان البريد مسجّلاً **وغير مفعّل** يُستبدل الحساب القديم (لا يُحجز البريد بسبب تسجيل لم يُكمل).
   - إن كان مفعّلاً → "البريد الإلكتروني مسجّل مسبقاً".
3. `VerifyEmailScreen` تُرسل الرمز فوراً وتعرض عدّاداً تنازلياً.
4. الرمز الصحيح → `markVerified()` + حفظ الجلسة → المستخدم داخل التطبيق مباشرة (بلا تسجيل دخول إضافي).
5. الخروج قبل التفعيل (زر الرجوع أو "التفعيل لاحقاً") يطلب تأكيداً؛ لاحقاً **تسجيل الدخول بنفس البيانات** يعيد فتح شاشة التفعيل تلقائياً.
6. الحسابات غير المفعّلة لا تظهر في قائمة الطلاب للمعلم.

## 4) نسيت كلمة المرور (حالة الاستخدام المطلوبة)

**الملف:** `lib/screens/auth/forgot_password_screen.dart`

1. المستخدم يسجّل بريده → يُتحقق من وجوده في SQLite.
2. يُرسل رمز OTP إلى بريده (أو يُعرض داخل التطبيق إن تعذّر الإرسال).
3. المستخدم يُدخل الرمز (حقل 6 أرقام يدعم اللصق والتحقق التلقائي عند اكتمال الخانات).
4. النظام يقارن الرمز المُدخل بالمرسَل (hash).
5. مطابق → واجهة كلمة المرور الجديدة → `UPDATE users SET password` فعلي.
   مختلف → رسالة **"الرمز غير صحيح، المتبقي N محاولات"** ويبقى في الخطوة 2.
   منتهٍ/تجاوز المحاولات → رسالة فشل + زر إعادة الإرسال.

## 5) إصلاح الكيبورد بعد الرجوع إلى التطبيق

**الملف:** `lib/widgets/keyboard_resume_fix.dart`

المشكلة المُبلَّغ عنها: عند حقل كلمة المرور أو رمز التحقق، الخروج من التطبيق والرجوع إليه يُبقي الحقل مُركَّزاً لكن لوحة المفاتيح لا تظهر.
الحل: مراقب `WidgetsBindingObserver`؛ عند `AppLifecycleState.resumed` وإن كان التركيز على حقل نص: `unfocus()` → إطار واحد → `requestFocus()` + `TextInput.show`. مُطبَّق على شاشات الدخول، التسجيل، التفعيل، والاستعادة. آمن على كل المنصات (لا يفعل شيئاً إن لم يكن هناك حقل مُركَّز).

## 6) لوحة OTP المشتركة

**الملف:** `lib/widgets/otp_panel.dart` — تُستخدم في التفعيل والاستعادة:
- حالة الإرسال (مؤشر) → "أرسلنا الرمز إلى بريدك" (أخضر) أو بطاقة الرمز مع **زر نسخ** عند التراجع.
- عدّاد `mm:ss` للصلاحية، زر إعادة الإرسال مع عدّاد 30 ثانية.
- حقل رقمي `autofillHints: oneTimeCode` + زر **لصق** + تحقق تلقائي عند 6 أرقام.
- `--dart-define=OTP_SHOW_IN_APP=true` يعرض الرمز داخل التطبيق دائماً (للعرض التجريبي أمام الأستاذ بدون انتظار البريد).

## 7) قاعدة البيانات v3

```sql
ALTER TABLE users ADD COLUMN verified INTEGER NOT NULL DEFAULT 0;
UPDATE users SET verified = 1;   -- كل الحسابات الموجودة قبل التحديث تُعدّ مفعّلة
```
مغطّاة بـ `test/db_upgrade_test.dart` (فتح قاعدة v2 حقيقية ثم الترقية والتحقق من الدخول وتغيير كلمة المرور).

## 8) الاختبارات (38)

| الملف | العدد | يغطي |
|---|---|---|
| `test/license_otp_test.dart` | 5 | منطق الترخيص (4) + تدفق الاستعادة كاملاً (بريد خاطئ → رمز خاطئ → صحيح → validation → تغيير فعلي) |
| `test/otp_email_test.dart` | 13 | OtpService (6 أرقام، مرة واحدة، 5 محاولات، انتهاء 10 دقائق، عزل البريد/الغرض، مهلة 30 ث، لا يُحفظ نصاً)، EmailService (المحتوى/الحالات)، التسجيل غير المفعّل، شاشة التفعيل (إرسال → خاطئ → صحيح → جلسة)، التراجع عند فشل SMTP مع زر نسخ، انتقال التسجيل → التفعيل |
| `test/db_upgrade_test.dart` | 1 | ترقية v2 → v3 |
| `test/screens_test.dart` | 19 | كل الشاشات على 360×780 بلا Overflow |

```bash
flutter analyze   # No issues found!
flutter test      # 38 tests passed
```

## 9) ملفات جديدة/معدّلة

```
lib/config/mail_config.dart                 جديد
lib/services/email/email_sender.dart        جديد (واجهة + conditional import)
lib/services/email/email_sender_io.dart     جديد (SMTP)
lib/services/email/email_sender_web.dart    جديد (تراجع)
lib/services/email/email_service.dart       جديد (قوالب + إرسال)
lib/services/otp_service.dart               جديد
lib/widgets/otp_panel.dart                  جديد
lib/widgets/keyboard_resume_fix.dart        جديد
lib/screens/auth/verify_email_screen.dart   جديد
lib/screens/auth/register_screen.dart       معدّل (→ التفعيل)
lib/screens/auth/login_screen.dart          معدّل (حساب غير مفعّل → التفعيل)
lib/screens/auth/forgot_password_screen.dart أُعيدت كتابته على OtpPanel
lib/services/storage_service.dart           DB v3 + verified/markVerified/isVerified
lib/models/models.dart                      AppUser.verified
lib/screens/about_screen.dart               الإصدار 1.3.0
tool/build_release.sh                       جديد (بناء مع SMTP بأمان)
android/smtp.properties.example             جديد
test/otp_email_test.dart, test/db_upgrade_test.dart, test/fake_email_sender.dart  جديد
pubspec.yaml                                1.3.0+6 + mailer
.gitignore                                  + lib/config/mail_secrets.dart, android/smtp.properties
```

## 10) ⚠️ ملاحظة مهمة عن توقيع `releases/EduAcademy-v1.3.0.apk`

ملف `release-key.jks` الأصلي **لم يكن متوفراً** في الحزمة العامة (أُزيل منها عمداً لأنها على رابط عام)، لذلك هذا الـ APK موقّع بمفتاح **مؤقت** (CN=EduAcademy Temp، SHA-256 `10f9c8f6…c28a`).

| الوضع | النتيجة |
|---|---|
| تثبيت جديد على جهاز بلا نسخة سابقة | يعمل مباشرة |
| تحديث فوق v1.2.0 الموقّع بالمفتاح الأصلي | أندرويد يرفض (`INSTALL_FAILED_UPDATE_INCOMPATIBLE`) — يلزم حذف القديم أو **إعادة البناء بالمفتاح الأصلي** |

**لإصدار النسخة الرسمية بالمفتاح الأصلي** (نفس مفتاح المشاريع الثلاثة، SHA-256 `52:BE:39:E7:F4:16…`):
```bash
cp /path/to/01_secrets/release-key.jks android/
cp /path/to/01_secrets/key.properties  android/
./tool/build_release.sh          # يستبدل releases/EduAcademy-v1.3.0.apk بنسخة بالمفتاح الأصلي
git add releases && git commit -m "v1.3.0: APK signed with original key" && git push
```
الكود والإصدار (`1.3.0+6`) لا يتغيّران؛ فقط التوقيع.

## 11) ما لم يتغيّر (للتأكيد)

- نظام الترخيص عن بُعد (`license.json`، الكود `770666`، 404 = قفل نهائي) كما هو بالضبط، واختباراته ناجحة.
- الحزمة `com.eduacademy.app`، مفتاح التوقيع، الأيقونة، الثيم، جميع شاشات الدورات/الدروس/الاختبارات/الشهادات/الإحصاءات.
