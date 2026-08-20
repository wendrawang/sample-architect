#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

failed=0

check_forbidden() {
  local pattern="$1"
  local message="$2"
  shift 2

  # Aturan ini menjaga kode, bukan prosa. Baris yang isinya diawali `//` adalah komentar
  # dan boleh menyebut nama API terlarang untuk menjelaskan kenapa API itu dihindari.
  local matches
  matches="$(rg --line-number "$pattern" "$@" | grep -vE '^[^:]+:[0-9]+:[[:space:]]*//' || true)"

  if [[ -n "$matches" ]]; then
    echo "$matches"
    echo "ERROR: $message"
    failed=1
  fi
}

check_forbidden 'import UIKit' \
  'ViewModel tidak boleh bergantung pada UIKit.' \
  Packages/Feature*/Sources --glob '*ViewModel.swift'

check_forbidden 'import Alamofire' \
  'Feature tidak boleh bergantung langsung pada Alamofire; gunakan CoreNetwork.APIClient.' \
  Packages/Feature*/Sources --glob '*.swift'

check_forbidden '^import Feature[A-Za-z]+' \
  'Feature biasa tidak boleh mengimpor feature lain; lakukan composition di FeatureMain.' \
  Packages/Feature*/Sources \
  --glob '*.swift' \
  --glob '!Packages/FeatureMain/**'

check_forbidden '\bUINavigationController\b' \
  'Navigation engine tunggal adalah NavigationStack; jangan menambahkan UINavigationController.' \
  App Packages --glob '*.swift'

check_forbidden '\bNavigationView\b' \
  'NavigationView deprecated sejak iOS 16; gunakan NavigationStack.' \
  App Packages --glob '*.swift'

check_forbidden 'NavigationLink\(destination:' \
  'NavigationLink(destination:) membangun destination sebelum dibutuhkan; gunakan NavigationLink(value:) atau router.push.' \
  App Packages --glob '*.swift'

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
