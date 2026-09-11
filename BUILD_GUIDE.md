# دليل البناء — EduAcademy

> لأي شخص يحمّل المستودع ويريد **تشغيل التطبيق أو إنتاج ملف APK بنفسه** خطوة بخطوة.
> آخر APK جاهز موجود في [`releases/EduAcademy-v1.3.0.apk`](releases/EduAcademy-v1.3.0.apk) — إن أردت التثبيت فقط بلا بناء، حمّله من هناك.

---

## 0. ما الموجود في المستودع؟

| المسار | الغرض |
|---|---|
| `releases/EduAcademy-v1.3.0.apk` | **آخر إصدار جاهز للتثبيت** (موقّع، android-arm64) — والسابق `v1.2.0` |
| `lib/` | كود التطبيق (34 ملف Dart) |
| `lib/config/mail_config.dart` | إعداد SMTP (يقرأ `--dart-define`، لا يحوي أسراراً) |
| `lib/services/email/`, `lib/services/otp_service.dart` | إرسال رموز التحقق بالبريد + محرك OTP (§7) |
| `tool/build_release.sh` | سكربت بناء APK يمرّر بيانات SMTP من `android/smtp.properties` |
| `android/smtp.properties.example` | نموذج إعداد SMTP (انسخه إلى `smtp.properties`) |
| `test/` | 5 ملفات اختبار — 38 اختباراً (`license_otp_test`, `otp_email_test`, `db_upgrade_test`, `screens_test`, `fake_email_sender`) |
| `assets/` | الصور والأصول |
| `android/` | مشروع أندرويد (الحزمة `com.eduacademy.app`) |
| `web/` | ملفات الويب (تشمل `sqlite3.wasm` و`sqflite_sw.js` لعمل SQLite في المتصفح) |
| `license.json` | **ملف التحكم عن بُعد** — يقرأه التطبيق عند كل تشغيل (§6) |
| `docs/CHANGELOG_v1.3.0.md` | **التوثيق الفني لإصدار 1.3.0** (OTP عبر البريد، تفعيل الحساب، DB v3، إصلاح الكيبورد) |
| `docs/CHANGELOG_v1.2.0.md` | التوثيق الفني المفصّل لإصدار 1.2.0 (الترخيص، الأيقونة، OTP) |
| `docs/make_icons.py` | سكربت توليد أيقونة الإطلاق |
| `docs/SESSION_LOG.md` | سجل التطوير: القرارات والمشاكل وحلولها |

---

## 1. المتطلبات

| الأداة | الإصدار | ملاحظة |
|---|---|---|
| Flutter | **3.35.4** (stable) | أي 3.35.x يعمل |
| Dart | 3.9.2 | يأتي مع Flutter |
| Java (JDK) | **17** | لا تستخدم 21 |
| Android SDK | compileSdk 36 / Build-Tools 35.0.0 | من Android Studio → SDK Manager |

```bash
flutter --version && java -version && flutter doctor
```

---

## 2. تحميل وتشغيل

```bash
git clone https://github.com/MoTechSys/Flutter-Native-App-022.git
cd Flutter-Native-App-022
flutter pub get
flutter analyze          # No issues found!
flutter test             # All tests passed!
flutter run              # جهاز/محاكي أندرويد
flutter run -d chrome    # معاينة ويب
```

---

## 3. بناء APK

### 3.أ — بمفتاح التوقيع الأصلي (نفس مفتاح الإصدارات المنشورة)
يلزمك ملفان **غير مضمّنين في المستودع** (في `.gitignore`):
```
android/release-key.jks
android/key.properties
```
شكل `android/key.properties`:
```properties
storePassword=********
keyPassword=********
keyAlias=release
storeFile=../release-key.jks
```
> اطلبهما من صاحب المشروع. نفس المفتاح مستخدم في المشاريع الثلاثة (EduAcademy, CarCare, Kitabi).
> **لتثبيت تحديث فوق نسخة مثبّتة يجب نفس المفتاح**، وإلا يطلب أندرويد حذف التطبيق أولاً.

```bash
# الطريقة الموصى بها (تمرّر بيانات SMTP تلقائياً من android/smtp.properties — §7):
./tool/build_release.sh

# أو يدوياً:
flutter build apk --release --target-platform android-arm64 \
  --dart-define=SMTP_USER=you@gmail.com --dart-define=SMTP_PASS=xxxxxxxxxxxxxxxx
# → build/app/outputs/flutter-apk/app-release.apk
```
كل المعالجات: `flutter build apk --release` · ملف لكل معمارية: `--split-per-abi`

> بدون `--dart-define=SMTP_*` يُبنى التطبيق ويعمل كاملاً، لكن رمز التحقق يُعرض داخل التطبيق بدل إرساله بالبريد.

### 3.ب — بلا مفتاح؟ أنشئ واحداً
```bash
keytool -genkey -v -keystore android/release-key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias release
```
ثم أنشئ `android/key.properties` كما أعلاه.

### 3.ج — للتجربة فقط
```bash
flutter build apk --debug
```

### التحقق والتثبيت
```bash
$ANDROID_HOME/build-tools/35.0.0/apksigner verify --print-certs build/app/outputs/flutter-apk/app-release.apk
$ANDROID_HOME/build-tools/35.0.0/aapt dump badging build/app/outputs/flutter-apk/app-release.apk | grep ^package
adb install -r build/app/outputs/flutter-apk/app-release.apk
```

---

## 4. إصدار نسخة جديدة

1. عدّل الكود.
2. `pubspec.yaml` → `version: X.Y.Z+N` — **N (versionCode) يجب أن يزيد** كل إصدار.
3. `flutter analyze && flutter test`.
4. `flutter build apk --release --target-platform android-arm64`.
5. انسخ الناتج إلى `releases/EduAcademy-vX.Y.Z.apk`.
6. حدّث ملاحظات الإصدار في `docs/`.
7. `git add -A && git commit -m "vX.Y.Z: ..." && git tag vX.Y.Z && git push origin main --tags`.

---

## 5. أخطاء شائعة

| الخطأ | السبب | الحل |
|---|---|---|
| `Keystore file not found` | ملفا التوقيع غير موجودين | §3.أ أو §3.ب |
| Gradle يفشل بـ `Unsupported class file major version` | JDK 21 | ثبّت JDK 17 واضبط `JAVA_HOME` |
| `INSTALL_FAILED_UPDATE_INCOMPATIBLE` | مفتاح توقيع مختلف | احذف القديم أو استخدم المفتاح الأصلي |
| `INSTALL_FAILED_VERSION_DOWNGRADE` | versionCode لم يزد | ارفع الرقم بعد `+` |
| شاشة "الترخيص موقوف نهائياً" | `license.json` غير موجود على GitHub (404) | أعِد الملف إلى جذر `main` |
| شاشة بيضاء على الويب | ملفات `web/sqlite3.wasm` / `sqflite_sw.js` مفقودة | لا تحذفها |
| رمز التحقق يُعرض داخل التطبيق بدل البريد | البناء بلا `SMTP_USER/PASS`، أو نسخة ويب | ابنِ عبر `tool/build_release.sh` مع `android/smtp.properties` (§7) |
| "رُفض الدخول إلى خادم البريد" | كلمة مرور الحساب العادية بدل App Password | أنشئ App Password من Google (تحقق بخطوتين مفعّل) |
| الرسالة لا تصل | مجلد Spam / حد إرسال Gmail (~500/يوم) | تحقق من Spam؛ استخدم "إعادة الإرسال" بعد 30 ث |

---

## 6. التحكم عن بُعد (`license.json`)

يقرأ التطبيق `https://github.com/MoTechSys/Flutter-Native-App-022/blob/main/license.json` عند كل تشغيل (GitHub API أولاً — بلا كاش — ثم الملف الخام كاحتياط).

```json
{ "active": true, "code": "770666", "message": "رسالة تظهر عند القفل" }
```

| تريد | افعل | النتيجة |
|---|---|---|
| تشغيل عادي | `"active": true` | يدخل مباشرة |
| إيقاف مع كود | `"active": false` + `code` | شاشة قفل تطلب الكود؛ بعد نجاحه يُحفظ ويفتح تلقائياً **ما لم تغيّر الكود** |
| إيقاف نهائي | **احذف الملف** | "موقوف نهائياً" — لا يقبل أي كود |
| بلا إنترنت | — | آخر حالة محفوظة |

التعديل يصل خلال ثوانٍ. الشيفرة في `lib/services/license_service.dart` ومغطّاة بالاختبارات.

---

## 7. رموز التحقق عبر البريد (SMTP) — جديد في 1.3.0

يرسل التطبيق رمز تحقق (6 أرقام، صالح 10 دقائق) إلى بريد المستخدم عند **إنشاء الحساب** وعند **نسيت كلمة المرور**. الإرسال يتم مباشرة من الجهاز عبر SMTP (حزمة `mailer`) بلا أي خادم وسيط.

### 7.أ — الإعداد (مرة واحدة)
1. حساب Gmail مخصّص للإرسال، مع **التحقق بخطوتين** مفعّلاً.
2. أنشئ **App password** (16 حرفاً) من https://myaccount.google.com/apppasswords
3. ```bash
   cp android/smtp.properties.example android/smtp.properties
   # املأ SMTP_USER و SMTP_PASS (المسافات في كلمة المرور لا تهم)
   ```
   الملف **مُتجاهَل في `.gitignore`** — لا يُرفع أبداً (المستودع عام).
4. `./tool/build_release.sh` → يقرأ الملف ويمرّره كـ `--dart-define` ويضع الناتج في `releases/`.

### 7.ب — كيف يتصرف التطبيق

| الحالة | السلوك |
|---|---|
| Android + SMTP مضبوط | يُرسل البريد؛ الشاشة تعرض "أرسلنا الرمز إلى بريدك" وعدّاداً 10:00 |
| فشل الإرسال (لا نت / رفض) | يعرض سبب الفشل **ويعرض الرمز داخل التطبيق مع زر نسخ** حتى لا يتعطل المستخدم |
| ويب (`flutter run -d chrome`) | المتصفح لا يدعم SMTP → الرمز يُعرض داخل التطبيق دائماً |
| بناء بلا `SMTP_*` | كذلك الرمز داخل التطبيق |
| `--dart-define=OTP_SHOW_IN_APP=true` | يُرسل البريد **ويعرض** الرمز أيضاً (مفيد للعرض أمام الأستاذ) |

### 7.ج — قواعد الرمز (OtpService)
6 أرقام · `Random.secure()` · صالح **10 دقائق** · 5 محاولات ثم يُلغى · إعادة إرسال بعد 30 ث · يُحفظ **مجزّأً** (SHA-256+salt) لا نصاً · مرة واحدة · مرتبط بالبريد والغرض (تسجيل/استعادة) · يبقى صالحاً بعد الخروج من التطبيق والرجوع.

### 7.د — تغيير حساب الإرسال لاحقاً
عدّل `android/smtp.properties` وأعد البناء. لا حاجة لتغيير أي كود. لاستخدام خادم غير Gmail: غيّر `SMTP_HOST`/`SMTP_PORT` (587 STARTTLS أو 465 SSL).
