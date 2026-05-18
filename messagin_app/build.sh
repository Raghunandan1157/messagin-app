#!/usr/bin/env bash
# Vercel build script — installs Flutter, writes .env from env vars, builds web.
set -euo pipefail

echo "→ Writing .env from Vercel environment"
cat > .env <<EOF
API_ENDPOINT=${API_ENDPOINT:-/api/sql}
API_TOKEN=${API_TOKEN:-missing}
NEON_HOST=${NEON_HOST:-unused-on-web}
NEON_DB=${NEON_DB:-unused-on-web}
NEON_USER=${NEON_USER:-unused-on-web}
NEON_PASSWORD=${NEON_PASSWORD:-unused-on-web}
DATABASE_URL=${DATABASE_URL:-unused-on-web}
EOF

FLUTTER_DIR="${HOME}/flutter"
if [ ! -d "${FLUTTER_DIR}" ]; then
  echo "→ Cloning Flutter (stable)"
  git clone --depth 1 --branch stable https://github.com/flutter/flutter.git "${FLUTTER_DIR}"
fi

export PATH="${FLUTTER_DIR}/bin:${PATH}"

echo "→ Flutter version"
flutter --version

echo "→ pub get"
flutter pub get

echo "→ build web"
flutter build web --release --no-tree-shake-icons

echo "→ done"
ls -la build/web | head
