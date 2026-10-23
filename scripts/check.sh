#!/usr/bin/env bash
# Tek kalite kapısı: sen de Claude da aynı komutu çalıştırırsınız.
# Bir adım başarısız olursa script durur ve sıfır olmayan kodla çıkar.
set -euo pipefail
cd "$(dirname "$0")/.."

step() { printf '\n==> %s\n' "$*"; }

# Yalnızca Command Line Tools ile derlerken swift-testing makro plugin'i derleyiciye
# kendiliğinden verilmiyor ("plugin for module 'TestingMacros' not found"); varsa elle ver.
testing_plugins="$(xcode-select -p)/usr/lib/swift/host/plugins/testing"
swiftc_extra=()
if [ -d "$testing_plugins" ]; then
  swiftc_extra=(-Xswiftc -plugin-path -Xswiftc "$testing_plugins")
fi

step "Format"
swift format lint --strict --recursive Sources Tests Package.swift

step "Katman kuralı (DisplayCore, CoreGraphics import edemez)"
if grep -rnE "import (CoreGraphics|AppKit|SwiftUI)" Sources/DisplayCore; then
  echo "DisplayCore platform çerçevesi import ediyor." >&2
  exit 1
fi

step "Derleme (uyarılar hata)"
swift build -Xswiftc -warnings-as-errors ${swiftc_extra[@]+"${swiftc_extra[@]}"}

step "Test"
swift test ${swiftc_extra[@]+"${swiftc_extra[@]}"}

step "App bundle (LSUIElement, imza)"
bundle_dir="$(mktemp -d)"
trap 'rm -rf "$bundle_dir"' EXIT
./scripts/bundle-app.sh --out "$bundle_dir" >/dev/null
app="$bundle_dir/DisplayDisconnect.app"
test -x "$app/Contents/MacOS/DisplayDisconnectApp"
if [ "$(plutil -extract LSUIElement raw -o - "$app/Contents/Info.plist")" != "true" ]; then
  echo "Info.plist: LSUIElement true değil (Dock ikonu çıkar)." >&2
  exit 1
fi
codesign --verify --deep --strict "$app"

step "Yer tutucu kontrolü"
if grep -rn "{{" CLAUDE.md docs/ >/dev/null 2>&1; then
  echo "Doldurulmamış {{...}} yer tutucuları var:" >&2
  grep -rn "{{" CLAUDE.md docs/ >&2
  exit 1
fi

printf '\nTüm kontroller geçti.\n'
