#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage: ios/scripts/build-community-ipa.sh [--output <path>] [--skip-ghosttykit]

Builds an unsigned cmux Community Release IPA for user-controlled re-signing
and sideloading. The package is not directly installable until it is signed for
the destination device by Xcode or a sideloading tool.
EOF
}

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
OUTPUT_PATH="$REPO_ROOT/cmux-community-ios.ipa"
SKIP_GHOSTTYKIT=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --output)
      if [[ -z "${2:-}" || "${2:-}" == --* ]]; then
        echo "error: --output requires a path" >&2
        exit 2
      fi
      OUTPUT_PATH="$2"
      shift 2
      ;;
    --skip-ghosttykit)
      SKIP_GHOSTTYKIT=1
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "error: unexpected argument: $1" >&2
      usage
      exit 2
      ;;
  esac
done

if [[ "$OUTPUT_PATH" != /* ]]; then
  OUTPUT_PATH="$PWD/$OUTPUT_PATH"
fi
mkdir -p "$(dirname "$OUTPUT_PATH")"

if [[ "$SKIP_GHOSTTYKIT" -eq 0 ]]; then
  "$REPO_ROOT/scripts/ensure-ghosttykit.sh"
fi

BUILD_ROOT="$(mktemp -d)"
PACKAGE_ROOT="$(mktemp -d)"
trap 'rm -rf "$BUILD_ROOT" "$PACKAGE_ROOT"' EXIT

BUILD_NUMBER="$(date -u +%Y%m%d%H%M%S)"
ARCHIVE_PATH="$BUILD_ROOT/cmux-community.xcarchive"

xcodebuild archive \
  -workspace "$REPO_ROOT/ios/cmux.xcworkspace" \
  -scheme cmux-ios \
  -configuration Release \
  -destination 'generic/platform=iOS' \
  -archivePath "$ARCHIVE_PATH" \
  -derivedDataPath "$BUILD_ROOT/DerivedData" \
  PRODUCT_BUNDLE_IDENTIFIER="io.github.lazarus931.cmux.community" \
  PRODUCT_DISPLAY_NAME="cmux Community" \
  CURRENT_PROJECT_VERSION="$BUILD_NUMBER" \
  CMUX_CRASH_REPORTING_ENABLED=NO \
  CMUX_IOS_AUTH_ENV=production \
  CMUX_API_BASE_URL="https://cmux.com" \
  CMUX_IROH_BROKER_BASE_URL="https://cmux.com" \
  CMUX_IOS_URL_SCHEME="cmux-ios" \
  CODE_SIGNING_ALLOWED=NO \
  CODE_SIGNING_REQUIRED=NO \
  CODE_SIGN_IDENTITY=""

APP_PATH="$ARCHIVE_PATH/Products/Applications/cmux.app"
if [[ ! -d "$APP_PATH" ]]; then
  echo "error: archive did not produce $APP_PATH" >&2
  exit 1
fi

mkdir -p "$PACKAGE_ROOT/Payload"
ditto "$APP_PATH" "$PACKAGE_ROOT/Payload/cmux.app"
rm -f "$OUTPUT_PATH"
(
  cd "$PACKAGE_ROOT"
  zip -qry "$OUTPUT_PATH" Payload
)

"$SCRIPT_DIR/verify-community-ipa.sh" "$OUTPUT_PATH"
echo "Community IPA: $OUTPUT_PATH"
