#!/usr/bin/env bash
# Vercel 웹 빌드 스크립트 (vercel.json의 buildCommand에서 실행)
#
# Vercel 빌드 이미지에는 Flutter가 없으므로 SDK를 받아서 빌드한다.
# 로컬에서도 같은 방식으로 실행할 수 있다: bash scripts/vercel-build.sh
#
# Vercel 프로젝트 환경변수:
#   SUPABASE_URL       Supabase 프로젝트 URL
#   SUPABASE_ANON_KEY  Supabase anon(publishable) 키
#   KAKAO_JS_KEY       카카오 JavaScript 키
#   API_BASE_URL       백엔드 API 주소
#   FLUTTER_VERSION    (선택) 기본값 3.47.5
set -euo pipefail

cd "$(dirname "$0")/.."

FLUTTER_VERSION="${FLUTTER_VERSION:-3.47.5}"
FLUTTER_HOME="${FLUTTER_HOME:-$HOME/flutter}"

# 1. Flutter SDK 준비
if ! command -v flutter >/dev/null 2>&1; then
  if [ ! -x "$FLUTTER_HOME/bin/flutter" ]; then
    echo "[vercel-build] Flutter $FLUTTER_VERSION 설치"
    git clone --depth 1 --branch "$FLUTTER_VERSION" \
      https://github.com/flutter/flutter.git "$FLUTTER_HOME"
  fi
  export PATH="$FLUTTER_HOME/bin:$PATH"
fi
flutter config --no-analytics >/dev/null
flutter --version

# 2. 빌드 (웹은 .env 대신 --dart-define으로 키를 주입한다)
if [ -z "${KAKAO_JS_KEY:-}" ] && [ -f .env ]; then
  # 로컬 실행 시 .env 값을 사용
  DEFINE_ARGS=(--dart-define-from-file=.env)
else
  DEFINE_ARGS=(
    --dart-define=KAKAO_JS_KEY="${KAKAO_JS_KEY:-}"
    --dart-define=API_BASE_URL="${API_BASE_URL:-}"
    --dart-define=SUPABASE_URL="${SUPABASE_URL:-}"
    --dart-define=SUPABASE_ANON_KEY="${SUPABASE_ANON_KEY:-}"
  )
fi

flutter pub get
flutter build web --release --no-wasm-dry-run "${DEFINE_ARGS[@]}"
