#!/usr/bin/env bash
set -euo pipefail

command -v flutter >/dev/null 2>&1 || {
  echo "Flutter nao encontrado."
  exit 1
}

backup="$(mktemp -d)"
preserve=(
  "pubspec.yaml"
  "analysis_options.yaml"
  "README.md"
  ".gitignore"
  ".env.example"
  "lib"
  "test"
  "docs"
  ".github"
  "tool"
)

for item in "${preserve[@]}"; do
  if [[ -e "$item" ]]; then
    cp -R "$item" "$backup/"
  fi
done

flutter create --platforms=ios --org com.snapgym --project-name snapgym .

for item in "${preserve[@]}"; do
  source_item="$backup/$item"
  if [[ -e "$source_item" ]]; then
    rm -rf "$item"
    cp -R "$source_item" "$item"
  fi
done

rm -rf "$backup"

flutter pub get
dart format lib test
flutter analyze
flutter test

echo "SnapGym iOS foundation pronta."
