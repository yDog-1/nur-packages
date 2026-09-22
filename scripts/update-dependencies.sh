#!/usr/bin/env bash

set -euo pipefail

validate_relative_path() {
  local path=$1
  local allow_dot=${2:-false}
  local component
  local -a components

  if [[ -z "$path" || "$path" == /* || "$path" == */ || "$path" == *//* || "$path" =~ [[:cntrl:]] ]]; then
    echo "Invalid relative path: $path" >&2
    return 1
  fi
  if [[ "$allow_dot" == true && "$path" == . ]]; then
    return
  fi
  IFS=/ read -r -a components <<<"$path"
  for component in "${components[@]}"; do
    if [[ "$component" == . || "$component" == .. ]]; then
      echo "Invalid relative path component: $path" >&2
      return 1
    fi
  done
}

nix flake update

# Package metadata remains declarative while nix-update handles version and hash changes.
metadata=$(nix eval --json --no-update-lock-file .#packages.x86_64-linux --apply '
  packages: builtins.mapAttrs (_: package: {
    version = package.version or null;
    updateFile = package.updateFile or null;
    bun2nixUpdate = package.bun2nixUpdate or null;
  }) packages')

mapfile -t packages < <(
  jq -r '
    to_entries
    | map(select(
        (.value.version | type) == "string" and (.value.version | length) > 0
        and (.value.updateFile | type) == "string" and (.value.updateFile | length) > 0
      ))
    | sort_by(.key)
    | .[].key
  ' <<<"$metadata"
)

if [[ "${#packages[@]}" -eq 0 ]]; then
  echo "No packages with update metadata were discovered." >&2
  exit 1
fi

for package in "${packages[@]}"; do
  config=$(jq -cer --arg package "$package" '.[$package]' <<<"$metadata")
  update_file=$(jq -er .updateFile <<<"$config")
  validate_relative_path "$update_file"
  if [[ ! -f "$update_file" ]]; then
    echo "Package update file does not exist: $update_file" >&2
    exit 1
  fi
  if ! jq -e '.bun2nixUpdate != null' <<<"$config" >/dev/null; then
    nix develop --no-update-lock-file --command \
      nix-update --flake --override-filename "$update_file" "$package"
    continue
  fi

  nix develop --no-update-lock-file --command \
    nix-update --flake --src-only --override-filename "$update_file" "$package"

  source_root=$(jq -er '.bun2nixUpdate.sourceRoot | select(type == "string" and length > 0)' <<<"$config")
  source_lock_file=$(jq -er '.bun2nixUpdate.sourceLockFile | select(type == "string" and length > 0)' <<<"$config")
  lock_file=$(jq -er '.bun2nixUpdate.lockFile | select(type == "string" and length > 0)' <<<"$config")
  nix_file=$(jq -er '.bun2nixUpdate.nixFile | select(type == "string" and length > 0)' <<<"$config")
  validate_relative_path "$source_root" true
  validate_relative_path "$source_lock_file"
  validate_relative_path "$lock_file"
  validate_relative_path "$nix_file"
  if [[ ! -f "$lock_file" || ! -f "$nix_file" ]]; then
    echo "Bun repository metadata for $package does not identify existing files." >&2
    exit 1
  fi
  source=$(nix build --no-link --print-out-paths --no-update-lock-file ".#$package.src")
  source_dir="$source/$source_root"

  if [[ ! -d "$source_dir" || ! -f "$source_dir/package.json" || ! -f "$source_dir/$source_lock_file" ]]; then
    echo "Bun source metadata for $package does not identify package.json and its lock file." >&2
    exit 1
  fi

  temp_dir=$(mktemp -d)
  trap 'rm -rf "$temp_dir"' EXIT
  cp -R --no-preserve=mode "$source_dir/." "$temp_dir"
  nix develop --no-update-lock-file --command \
    bun install --cwd "$temp_dir" --frozen-lockfile --ignore-scripts --no-progress
  install -Dm644 "$source_dir/$source_lock_file" "$lock_file"
  nix develop --no-update-lock-file --command bun2nix -l "$lock_file" -o "$nix_file"
  nix develop --no-update-lock-file --command deadnix --edit "$nix_file"
  nix fmt "$nix_file"
  rm -rf "$temp_dir"
  trap - EXIT
done
