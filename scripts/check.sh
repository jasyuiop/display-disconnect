#!/usr/bin/env bash
# Tek kalite kapısı: sen de Claude da aynı komutu çalıştırırsınız.
# Bir adım başarısız olursa script durur ve sıfır olmayan kodla çıkar.
set -euo pipefail
cd "$(dirname "$0")/.."

# /kickoff bu iki satırı kaldırır. Yapılandırılmamış bir kapı asla "yeşil" görünmemeli.
echo "scripts/check.sh henüz yapılandırılmadı" >&2
exit 1

step() { printf '\n==> %s\n' "$*"; }

step "Format"
# Python: ruff format --check .
# Rust:   cargo fmt --check
# Node:   npx prettier --check .

step "Lint"
# Python: ruff check .
# Rust:   cargo clippy --all-targets -- -D warnings
# Node:   npx eslint .

step "Tip kontrolü"
# Python: mypy src
# Node:   npx tsc --noEmit

step "Test"
# Python: pytest -q
# Rust:   cargo test
# Node:   npm test

step "Yer tutucu kontrolü"
if grep -rn "{{" CLAUDE.md docs/ >/dev/null 2>&1; then
  echo "Doldurulmamış {{...}} yer tutucuları var:" >&2
  grep -rn "{{" CLAUDE.md docs/ >&2
  exit 1
fi

printf '\nTüm kontroller geçti.\n'
