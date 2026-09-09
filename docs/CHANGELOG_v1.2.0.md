# EduAcademy – سجل التغييرات والتوثيق الفني (v1.1.0 → v1.2.0)

> مستودع: `MoTechSys/Flutter-Native-App-022` – حزمة: `com.eduacademy.app`
> ملف التحكم عن بُعد: `license.json` في جذر المستودع (فرع main)

---

## v1.2.0 (build 5)

### 1) الترخيص عن بُعد – إعادة كتابة كاملة
**الملفات:** `lib/services/license_service.dart`, `lib/screens/license_screen.dart`, `lib/main.dart`

**الأخطاء التي كانت موجودة:**
1. القراءة من `raw.githubusercontent.com` تمر عبر CDN يحتفظ بالملف حتى 5 دقائق
   (`cache-control: max-age=300`) حتى مع معامل `?t=` → التطبيق يقرأ نسخة قديمة.
2. الكود المُدخل لم يكن يُحفظ ("الجلسة الحالية فقط") → كل تشغيل يطلب الكود مجدداً.
3. ترويسة `Accept` بقيم متعددة تجعل GitHub يعيدها كـ Content-Type غير صالح
   → `res.body` يرمي استثناء ويُعامَل كـ "لا إنترنت".

**التصميم الجديد:**
- المصدر الأساسي: **GitHub Contents API**
  `https://api.github.com/repos/<owner>/<repo>/contents/license.json?ref=main`
  (يقرأ الكوميت الحالي مباشرة بلا CDN؛ المحتوى base64 → decode).
  الاحتياط: الملف الخام مع `?nocache=<ts>` وترويسات `no-cache`.
- فك الجسم بـ `utf8.decode(res.bodyBytes)` بدل `res.body`.
- `http.Client client` ثابت قابل للاستبدال (للاختبارات بـ `MockClient`).

**جدول السلوك:**

| الملف | النتيجة |
|---|---|
| `active: true` | يفتح فوراً، يمسح `lic_blocked` |
| `active: false` | يطلب كود؛ إذا طابق `code` → يُحفظ في `lic_activated_code` ويفتح في كل تشغيل ما دام نفس الكود في الملف |
| تغيير `code` | `saved != code` → قفل مجدداً |
| 404 (ملف/مستودع محذوف) | `lic_deleted=true`, قفل نهائي، `activate()` ترجع false دائماً |
| لا إنترنت | آخر حالة محفوظة (`offline=true`) |

مفاتيح SharedPreferences: `lic_blocked`, `lic_message`, `lic_code`, `lic_activated_code`, `lic_deleted`.

**واجهة القفل:** تستقبل `LicenseState` كاملاً؛ تخفي حقل الكود عند 404؛ زر
"إعادة التحقق من الترخيص" يستدعي `check()` مباشرة.

**الاختبارات:** `test/license_otp_test.dart` مجموعة `license logic` (4 اختبارات
بـ MockClient تحاكي API + raw + 404 + offline).

### 2) أيقونة التطبيق (Adaptive Icon)
**السبب:** الصورة المصدر كانت RGB بلا ألفا ومرسوم فيها نمط الشفافية (مربعات) +
لا يوجد `mipmap-anydpi-v26` → أندرويد يعرض الصورة الكاملة مصغّرة بخلفية سوداء.

**الحل:** سكربت `/home/user/make_icons.py` (Pillow):
- يقص بلاطة الشعار، يفصل الرسم الأبيض/الأخضر عن الخلفية.
- `ic_launcher_background.png` = تدرج بنفسجي (`5B4BDB → 7C3AB8`) 108dp لكل دقّة.
- `ic_launcher_foreground.png` = الرسم فقط على شفاف داخل منطقة الأمان (~52%).
- `ic_launcher.png` (مربع مدوّر) و `ic_launcher_round.png` للأجهزة القديمة.
- `mipmap-anydpi-v26/ic_launcher.xml` و `ic_launcher_round.xml`.
- تحديث أيقونات الويب + favicon + `assets/icons/app_icon.png`.

التحقق: `aapt2 dump badging` → `application-icon-*: res/<xml>` (تكيّفي).

### 3) نسيت كلمة المرور – OTP بثلاث خطوات
**الملف:** `lib/screens/auth/forgot_password_screen.dart`
1. البريد المسجّل (تحقق من وجوده في SQLite).
2. توليد رمز 6 أرقام `Random.secure()` صالح 5 دقائق، بطاقة عرض + زر نسخ
   (`Clipboard.setData`) + إعادة إرسال + حد 5 محاولات.
3. التحقق ثم كلمة مرور جديدة + تأكيد (Validation) → `resetPassword()`.

مؤشر خطوات 1-2-3، زر "تغيير البريد" للرجوع. الصفوف داخل البطاقة `Expanded/FittedBox`
و `Wrap` لتفادي overflow على 360px (كُشف بالاختبار وأُصلح).

### 4) تحسينات عامة
- `showSnack` يستخدم `removeCurrentSnackBar()` حتى تظهر الرسالة الجديدة فوراً.
- الإصدار `1.2.0+5` في pubspec وشاشة "حول".

---

## v1.1.0 (build 4) – ملخص
- حفظ دور المستخدم (طالب/معلم) عند التسجيل (كان يُهمل).
- DB v2: جدول `progress(studentEmail, lessonId)` + عمود `notes.studentEmail`
  → التقدّم والملاحظات خاصة بكل طالب (مع `onUpgrade`).
- شاشة الطلاب للمعلم + ملف الطالب (حذف حساب).
- شاشة إدارة أسئلة الاختبار (CRUD) للمعلم.
- تحميل الشهادة فعلياً: `RepaintBoundary → PNG` حفظ (`path_provider`) + مشاركة (`share_plus`).
- لوحة رئيسية مختلفة للمعلم، تنظيف بقايا المشروع السابق.

## أوامر التحقق
```bash
flutter analyze                     # No issues
flutter test                        # 24 tests
flutter build apk --release --target-platform android-arm64
```
