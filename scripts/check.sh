#!/usr/bin/env bash
# Tek kalite kapısı: sen de Claude da aynı komutu çalıştırırsınız.
# Bir adım başarısız olursa script durur ve sıfır olmayan kodla çıkar.
set -euo pipefail
cd "$(dirname "$0")/.."

step() { printf '\n==> %s\n' "$*"; }

step "Format"
swift format lint --strict --recursive Sources Tests Package.swift

step "Katman kuralı (DisplayCore, CoreGraphics import edemez)"
if grep -rnE "import (CoreGraphics|AppKit|SwiftUI)" Sources/DisplayCore; then
  echo "DisplayCore platform çerçevesi import ediyor." >&2
  exit 1
fi

step "Derleme (uyarılar hata)"
swift build -Xswiftc -warnings-as-errors

step "Test"
swift test

step "Yer tutucu kontrolü"
if grep -rn "{{" CLAUDE.md docs/ >/dev/null 2>&1; then
  echo "Doldurulmamış {{...}} yer tutucuları var:" >&2
  grep -rn "{{" CLAUDE.md docs/ >&2
  exit 1
fi

printf '\nTüm kontroller geçti.\n'
