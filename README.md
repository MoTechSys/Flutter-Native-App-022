# EduAcademy — إيدو أكاديمي

تطبيق أكاديمي لإدارة دورات تعليمية: دورات ودروس وملاحظات واختبارات وشهادات وإحصاءات، بدورَي طالب ومعلم.

**الحزمة:** `com.eduacademy.app` · **الإصدار الحالي:** 1.2.0 (build 5) · Flutter 3.35.4

**📱 آخر APK جاهز للتثبيت:** [`releases/EduAcademy-v1.2.0.apk`](releases/EduAcademy-v1.2.0.apk)
**🛠 كيف تبني APK بنفسك:** [`BUILD_GUIDE.md`](BUILD_GUIDE.md)
**📓 سجل التطوير والقرارات:** [`docs/SESSION_LOG.md`](docs/SESSION_LOG.md)

## الأدوار
- **طالب**: يتصفح الدورات، يفتح الدروس، يكتب ملاحظاته، يحل الاختبارات، يحصل على شهادات ويرى إحصاءاته.
- **معلم**: كل ما سبق + إدارة الدورات والدروس والأسئلة ومتابعة الطلاب.

## التشغيل السريع
```bash
flutter pub get
flutter analyze
flutter test
flutter build apk --release --target-platform android-arm64
```

## التحكم عن بُعد
`license.json` في جذر هذا المستودع يتحكم في التطبيق عند كل تشغيل (`active: true/false` + `code`؛ حذف الملف = قفل نهائي). التفاصيل في `BUILD_GUIDE.md` §6.
