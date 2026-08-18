#!/bin/zsh
set -euo pipefail

cd "${0:A:h}"

if ! command -v xcodegen >/dev/null 2>&1 || ! command -v rg >/dev/null 2>&1; then
  if ! command -v brew >/dev/null 2>&1; then
    echo "Homebrew belum tersedia. Install dari https://brew.sh lalu jalankan file ini lagi."
    exit 1
  fi
fi

if ! command -v xcodegen >/dev/null 2>&1; then
  brew install xcodegen
fi

if ! command -v rg >/dev/null 2>&1; then
  brew install ripgrep
fi

xcodegen generate --spec project.yml
open ModularBank.xcodeproj
