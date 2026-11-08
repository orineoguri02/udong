#!/bin/sh
set -e

echo "🔥 CI POST CLONE STARTED"

REPO="$CI_PRIMARY_REPOSITORY_PATH"
FLUTTER_PATH="$HOME/flutter"

cd "$REPO"

# ── 1. Flutter 설치 ───────────────────────────────────────
echo "[1] Flutter 설치"
if [ ! -d "$FLUTTER_PATH" ]; then
  git clone https://github.com/flutter/flutter.git --depth 1 -b stable "$FLUTTER_PATH"
else
  echo "  이미 존재, skip"
fi

export PATH="$FLUTTER_PATH/bin:$PATH"
flutter --version

# ── 2. 민감 파일 복원 (빌드 전에 필요) ────────────────────
echo "[2] 민감 파일 복원"

# .env (pubspec asset)
if [ -n "$DOT_ENV" ]; then
  echo "$DOT_ENV" | base64 --decode > "$REPO/.env"
  echo "  ✅ .env 복원 완료"
else
  echo "  ⚠️ DOT_ENV 없음"
fi

# Secrets.xcconfig (Info.plist 변수)
if [ -n "$GOOGLE_CLIENT_ID_PREFIX" ]; then
  cat > "$REPO/ios/Flutter/Secrets.xcconfig" << EOF
GOOGLE_CLIENT_ID_PREFIX = $GOOGLE_CLIENT_ID_PREFIX
EOF
  echo "  ✅ Secrets.xcconfig 생성 완료"
else
  echo "  ⚠️ GOOGLE_CLIENT_ID_PREFIX 없음"
fi

# ── 3. Flutter 준비 ───────────────────────────────────────
echo "[3] flutter precache"
flutter precache --ios

echo "[4] flutter pub get"
flutter pub get

# 🔥 핵심
echo "[5] flutter build ios"
flutter build ios --no-codesign

# ── 4. Pods 설치 ─────────────────────────────────────────
echo "[6] pod install"
cd "$REPO/ios"

rm -rf Pods Podfile.lock   # 🔥 이거 추가 (핵심)

pod install

cd ..

echo "✅ CI POST CLONE DONE"
exit 0
