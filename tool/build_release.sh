#!/usr/bin/env bash
# ============================================================
# EduAcademy - بناء APK إصدار مع تمرير بيانات SMTP بأمان
#
# الاستخدام:
#   1) انسخ android/smtp.properties.example إلى android/smtp.properties
#      واملأ SMTP_USER و SMTP_PASS (كلمة مرور تطبيق Gmail، 16 حرفاً).
#      الملف مُتجاهَل في .gitignore ولن يُرفع.
#   2) ./tool/build_release.sh            # arm64 (الافتراضي)
#      ./tool/build_release.sh --all      # كل المعالجات
#
# بدون smtp.properties: يُبنى التطبيق ويعمل، لكن رمز التحقق يُعرض داخل
# التطبيق (Fallback) بدل إرساله بالبريد.
# ============================================================
set -euo pipefail
cd "$(dirname "$0")/.."

PROPS="android/smtp.properties"
DEFINES=()
if [[ -f "$PROPS" ]]; then
  while IFS='=' read -r k v; do
    k="${k// /}"; [[ -z "$k" || "$k" == \#* ]] && continue
    v="${v%\"}"; v="${v#\"}"
    case "$k" in
      SMTP_HOST|SMTP_PORT|SMTP_USER|SMTP_PASS) DEFINES+=("--dart-define=$k=$v");;
    esac
  done < "$PROPS"
  echo "✔ SMTP config loaded from $PROPS (${#DEFINES[@]} keys)"
else
  echo "⚠ $PROPS not found → OTP will be shown in-app (no email sending)"
fi

if [[ ! -f android/key.properties ]]; then
  echo "⚠ android/key.properties missing → APK will be signed with DEBUG key"
fi

TARGET=(--target-platform android-arm64)
[[ "${1:-}" == "--all" ]] && TARGET=()

flutter pub get
flutter analyze
flutter build apk --release "${TARGET[@]}" "${DEFINES[@]}"

VER=$(grep -E '^version:' pubspec.yaml | awk '{print $2}' | cut -d+ -f1)
mkdir -p releases
cp build/app/outputs/flutter-apk/app-release.apk "releases/EduAcademy-v${VER}.apk"
echo "✔ releases/EduAcademy-v${VER}.apk"
