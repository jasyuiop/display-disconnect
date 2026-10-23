#!/usr/bin/env bash
# Packages release assets: the app (zip), the CLI (tar.gz) and SHA256SUMS.
# Usage: scripts/package-release.sh --out DIR [--configuration debug|release]
set -euo pipefail
cd "$(dirname "$0")/.."

out=""
configuration="release"
while [ $# -gt 0 ]; do
  case "$1" in
    --out) out="${2:?--out needs a directory}"; shift 2 ;;
    --configuration) configuration="${2:?--configuration needs a value}"; shift 2 ;;
    *) echo "Unknown argument: $1" >&2; exit 64 ;;
  esac
done
if [ -z "$out" ]; then
  echo "--out is required." >&2
  exit 64
fi
case "$configuration" in
  debug | release) ;;
  *) echo "--configuration must be debug or release: $configuration" >&2; exit 64 ;;
esac

version="$(sed -n 's/.*static let version = "\(.*\)".*/\1/p' Sources/DisplayCore/AppInfo.swift)"
if [ -z "$version" ]; then
  echo "Could not read the version from Sources/DisplayCore/AppInfo.swift." >&2
  exit 1
fi

mkdir -p "$out"
work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT

app="$(./scripts/bundle-app.sh --out "$work" --configuration "$configuration")"
swift build -c "$configuration" --product dispctl >&2
cli="$(swift build -c "$configuration" --show-bin-path)/dispctl"
if [ ! -x "$cli" ]; then
  echo "Built CLI not found: $cli" >&2
  exit 1
fi

app_zip="DisplayDisconnect-$version-arm64.zip"
cli_tar="dispctl-$version-arm64.tar.gz"
ditto -c -k --keepParent "$app" "$out/$app_zip"
cp "$cli" "$work/dispctl"
tar -czf "$out/$cli_tar" -C "$work" dispctl
(cd "$out" && shasum -a 256 "$app_zip" "$cli_tar" > SHA256SUMS)

echo "$out"
