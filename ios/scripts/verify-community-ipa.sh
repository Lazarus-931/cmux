#!/usr/bin/env bash
set -euo pipefail

usage() {
  echo "Usage: ios/scripts/verify-community-ipa.sh <path-to-ipa>" >&2
}

if [[ $# -ne 1 ]]; then
  usage
  exit 2
fi

IPA_PATH="$1"
if [[ ! -f "$IPA_PATH" ]]; then
  echo "error: IPA not found: $IPA_PATH" >&2
  exit 1
fi

WORK_DIR="$(mktemp -d)"
trap 'rm -rf "$WORK_DIR"' EXIT

unzip -q "$IPA_PATH" -d "$WORK_DIR"
if [[ ! -d "$WORK_DIR/Payload" ]]; then
  echo "error: IPA has no Payload directory" >&2
  exit 1
fi

APP_COUNT="$(find "$WORK_DIR/Payload" -maxdepth 1 -type d -name '*.app' | wc -l | tr -d ' ')"
if [[ "$APP_COUNT" -ne 1 ]]; then
  echo "error: expected exactly one Payload/*.app, found $APP_COUNT" >&2
  exit 1
fi

APP_PATH="$(find "$WORK_DIR/Payload" -maxdepth 1 -type d -name '*.app' | head -n 1)"
INFO_PLIST="$APP_PATH/Info.plist"
if [[ ! -f "$INFO_PLIST" ]]; then
  echo "error: app bundle has no Info.plist" >&2
  exit 1
fi

read_plist() {
  /usr/libexec/PlistBuddy -c "Print :$1" "$INFO_PLIST" 2>/dev/null || true
}

assert_plist() {
  local key="$1"
  local expected="$2"
  local actual
  actual="$(read_plist "$key")"
  if [[ "$actual" != "$expected" ]]; then
    echo "error: $key is '${actual:-<absent>}', expected '$expected'" >&2
    exit 1
  fi
}

assert_plist CFBundleIdentifier "io.github.lazarus931.cmux.community"
assert_plist CFBundleDisplayName "cmux Community"
assert_plist CMUXAuthEnvironment "production"
assert_plist CMUXApiBaseURL "https://cmux.com"
assert_plist CMUXIrohBrokerBaseURL "https://cmux.com"
assert_plist CMUXCrashReportingEnabled "NO"

if [[ -e "$APP_PATH/embedded.mobileprovision" ]]; then
  echo "error: community IPA unexpectedly contains a provisioning profile" >&2
  exit 1
fi

if codesign -d "$APP_PATH" >/dev/null 2>&1; then
  echo "error: community IPA unexpectedly contains an app signature" >&2
  exit 1
fi

echo "PASS: unsigned community IPA verified"
