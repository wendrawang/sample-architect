#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

failed=0

check_forbidden() {
  local pattern="$1"
  local message="$2"
  shift 2

  if rg --line-number "$pattern" "$@"; then
    echo "ERROR: $message"
    failed=1
  fi
}

check_forbidden 'import UIKit' \
  'ViewModel tidak boleh bergantung pada UIKit.' \
  Packages/Feature*/Sources --glob '*ViewModel.swift'

check_forbidden 'Navigation(View|Link|Stack)' \
  'Navigation SwiftUI dilarang; gunakan Coordinator + UINavigationController.' \
  Packages/Feature*/Sources --glob '*.swift'

check_forbidden '\bAnyView\b' \
  'AnyView dilarang pada hot path karena menghapus type identity.' \
  App Packages --glob '*.swift'

check_forbidden 'exit\(0\)|fatalError\("root' \
  'Jangan menutup aplikasi secara paksa saat root device terdeteksi.' \
  App Packages --glob '*.swift'

if [[ "$failed" -ne 0 ]]; then
  exit 1
fi

echo "Architecture checks passed."

