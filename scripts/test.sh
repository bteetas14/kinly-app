#!/usr/bin/env sh
set -eu

(cd backend && go test ./...)

if command -v flutter >/dev/null 2>&1; then
  (cd mobile && flutter test)
else
  echo "Flutter is not installed; skipped mobile tests."
fi
