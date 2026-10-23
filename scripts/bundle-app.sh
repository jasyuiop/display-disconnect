#!/usr/bin/env bash
# DisplayDisconnect.app paketini oluşturur (LSUIElement: Dock ikonu yok, ad-hoc imzalı).
# Kullanım: scripts/bundle-app.sh [--out DİZİN] [--configuration debug|release]
# Çıktı yolu stdout'a yazılır; varsayılan: .build/bundle/DisplayDisconnect.app
set -euo pipefail
cd "$(dirname "$0")/.."

out=".build/bundle"
configuration="debug"
while [ $# -gt 0 ]; do
  case "$1" in
    --out) out="${2:?--out bir dizin ister}"; shift 2 ;;
    --configuration) configuration="${2:?--configuration bir değer ister}"; shift 2 ;;
    *) echo "Bilinmeyen argüman: $1" >&2; exit 64 ;;
  esac
done
case "$configuration" in
  debug | release) ;;
  *) echo "--configuration debug veya release olmalı: $configuration" >&2; exit 64 ;;
esac

version="$(sed -n 's/.*static let version = "\(.*\)".*/\1/p' Sources/DisplayCore/AppInfo.swift)"
if [ -z "$version" ]; then
  echo "Sürüm Sources/DisplayCore/AppInfo.swift içinden okunamadı." >&2
  exit 1
fi

swift build -c "$configuration" --product DisplayDisconnectApp >&2
binary="$(swift build -c "$configuration" --show-bin-path)/DisplayDisconnectApp"
if [ ! -x "$binary" ]; then
  echo "Derlenmiş uygulama bulunamadı: $binary" >&2
  exit 1
fi

app="$out/DisplayDisconnect.app"
rm -rf "$app"
mkdir -p "$app/Contents/MacOS"
cp "$binary" "$app/Contents/MacOS/DisplayDisconnectApp"

cat > "$app/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleIdentifier</key><string>io.github.display-disconnect.app</string>
  <key>CFBundleName</key><string>DisplayDisconnect</string>
  <key>CFBundleDisplayName</key><string>Display Disconnect</string>
  <key>CFBundleExecutable</key><string>DisplayDisconnectApp</string>
  <key>CFBundlePackageType</key><string>APPL</string>
  <key>CFBundleShortVersionString</key><string>${version}</string>
  <key>CFBundleVersion</key><string>${version}</string>
  <key>LSMinimumSystemVersion</key><string>14.0</string>
  <key>LSUIElement</key><true/>
  <key>NSHighResolutionCapable</key><true/>
</dict>
</plist>
PLIST

plutil -lint "$app/Contents/Info.plist" >&2
codesign --force --deep --sign - "$app" >&2
echo "$app"
