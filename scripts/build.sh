#!/bin/sh
set -eu
cd "$(dirname "$0")/.."
if ! xcodebuild -version >/dev/null 2>&1; then
  echo 'Xcode is required. Install/select Xcode 27.1 beta for the Duo SDK.' >&2
  exit 1
fi
exec xcodebuild -project DuoSync.xcodeproj -scheme DuoSync \
  -configuration Debug -destination 'generic/platform=iOS Simulator' \
  -derivedDataPath "${TMPDIR:-/tmp}/duosync-derived-data" CODE_SIGNING_ALLOWED=NO build
