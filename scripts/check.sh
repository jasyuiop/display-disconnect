#!/usr/bin/env bash
# The single quality gate: you and Claude run the same command.
# If a step fails, the script stops and exits non-zero.
set -euo pipefail
cd "$(dirname "$0")/.."

step() { printf '\n==> %s\n' "$*"; }

# With only the Command Line Tools installed, the swift-testing macro plugin is not passed to the
# compiler automatically ("plugin for module 'TestingMacros' not found"); pass it explicitly.
testing_plugins="$(xcode-select -p)/usr/lib/swift/host/plugins/testing"
swiftc_extra=()
if [ -d "$testing_plugins" ]; then
  swiftc_extra=(-Xswiftc -plugin-path -Xswiftc "$testing_plugins")
fi

step "Language check (English only)"
# Turkish letters as UTF-8 byte sequences, so this file does not match itself.
turkish_letters=$'\xc3\xa7|\xc3\x87|\xc4\x9f|\xc4\x9e|\xc4\xb1|\xc4\xb0|\xc3\xb6|\xc3\x96|\xc5\x9f|\xc5\x9e|\xc3\xbc|\xc3\x9c'
if LC_ALL=C grep -rnE "$turkish_letters" Sources Tests scripts; then
  echo "Turkish characters found above; user-facing text, comments and scripts must be English." >&2
  exit 1
fi

step "Format"
swift format lint --strict --recursive Sources Tests Package.swift

step "Layer rule (DisplayCore must not import CoreGraphics, AppKit or SwiftUI)"
if grep -rnE "import (CoreGraphics|AppKit|SwiftUI)" Sources/DisplayCore; then
  echo "DisplayCore imports a platform framework." >&2
  exit 1
fi

step "Build (warnings are errors)"
swift build -Xswiftc -warnings-as-errors ${swiftc_extra[@]+"${swiftc_extra[@]}"}

step "Test"
swift test ${swiftc_extra[@]+"${swiftc_extra[@]}"}

step "App bundle (LSUIElement, signature)"
bundle_dir="$(mktemp -d)"
trap 'rm -rf "$bundle_dir"' EXIT
./scripts/bundle-app.sh --out "$bundle_dir" >/dev/null
app="$bundle_dir/DisplayDisconnect.app"
test -x "$app/Contents/MacOS/DisplayDisconnectApp"
if [ "$(plutil -extract LSUIElement raw -o - "$app/Contents/Info.plist")" != "true" ]; then
  echo "Info.plist: LSUIElement is not true (a Dock icon would appear)." >&2
  exit 1
fi
expected_id="io.github.jasyuiop.display-disconnect"
actual_id="$(plutil -extract CFBundleIdentifier raw -o - "$app/Contents/Info.plist")"
if [ "$actual_id" != "$expected_id" ]; then
  echo "Info.plist: CFBundleIdentifier is $actual_id, expected $expected_id." >&2
  exit 1
fi
codesign --verify --deep --strict "$app"

step "Release packaging (zip, tarball, checksums)"
dist_dir="$(mktemp -d)"
trap 'rm -rf "$bundle_dir" "$dist_dir"' EXIT
version="$(sed -n 's/.*static let version = "\(.*\)".*/\1/p' Sources/DisplayCore/AppInfo.swift)"
./scripts/package-release.sh --out "$dist_dir" --configuration debug >/dev/null
app_zip="$dist_dir/DisplayDisconnect-$version-arm64.zip"
cli_tar="$dist_dir/dispctl-$version-arm64.tar.gz"
zip_listing="$(unzip -l "$app_zip")"
tar_listing="$(tar -tzf "$cli_tar")"
case "$zip_listing" in
  *"DisplayDisconnect.app/Contents/Info.plist"*) ;;
  *) echo "Release zip lacks the app's Info.plist." >&2; exit 1 ;;
esac
if [ "$tar_listing" != "dispctl" ]; then
  echo "Release tarball must contain exactly dispctl, found: $tar_listing" >&2
  exit 1
fi
(cd "$dist_dir" && shasum -a 256 -c SHA256SUMS >/dev/null)

# Internal notes are not part of the published repository; check them only where they exist.
if [ -f CLAUDE.md ] || [ -d docs ]; then
  step "Placeholder check (internal notes)"
  if grep -rn "{{" CLAUDE.md docs/ >/dev/null 2>&1; then
    echo "Unfilled {{...}} placeholders found:" >&2
    grep -rn "{{" CLAUDE.md docs/ >&2
    exit 1
  fi
fi

printf '\nAll checks passed.\n'
