#!/usr/bin/env bash
set -euo pipefail

readonly NPM_PACKAGE="rea-agents"
readonly ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

fail() {
  printf 'error: %s\n' "$1" >&2
  exit 1
}

main() {
  local requested_version="${1:-}"
  local current_version version tarball_url src_hash work_dir deps_hash

  for tool in curl jq nix npm sed tar; do
    command -v "$tool" >/dev/null 2>&1 || fail "missing required tool: $tool"
  done

  cd "$ROOT_DIR"
  current_version="$(sed -n 's/^  version = "\([^"]*\)";/\1/p' packages/rea.nix)"
  [[ -n "$current_version" ]] || fail "could not read the packaged version"

  if [[ -n "$requested_version" ]]; then
    version="${requested_version#v}"
  else
    version="$(npm view "$NPM_PACKAGE" dist-tags.latest)"
  fi
  [[ -n "$version" ]] || fail "could not determine the upstream version"
  [[ "$version" != *-* ]] || fail "${version} is not a stable release"

  printf 'Current version: %s\nLatest version:  %s\n' "$current_version" "$version"
  if [[ "$current_version" == "$version" ]]; then
    printf 'Already up to date.\n'
    exit 0
  fi

  tarball_url="$(npm view "${NPM_PACKAGE}@${version}" dist.tarball)"
  src_hash="$(nix store prefetch-file --json "$tarball_url" | jq -r .hash)"

  # Regenerate the lockfile against the same package.json the build patches.
  work_dir="$(mktemp -d)"
  trap "rm -rf '${work_dir}'" EXIT
  curl --silent --show-error --fail --location "$tarball_url" | tar -xz -C "$work_dir"
  jq 'del(.optionalDependencies, .devDependencies)' "$work_dir/package/package.json" >"$work_dir/package.json"
  mv "$work_dir/package.json" "$work_dir/package/package.json"
  (cd "$work_dir/package" && npm install --package-lock-only --ignore-scripts --no-audit --no-fund >/dev/null)
  cp "$work_dir/package/package-lock.json" packages/rea-package-lock.json
  deps_hash="$(nix run nixpkgs#prefetch-npm-deps -- packages/rea-package-lock.json 2>/dev/null)"
  [[ "$deps_hash" == sha256-* ]] || fail "could not compute the npm dependency hash"

  sed -i \
    -e "s|^  version = \"${current_version}\";|  version = \"${version}\";|" \
    -e "/src = fetchurl {/,/};/ s|^    hash = .*|    hash = \"${src_hash}\";|" \
    -e "s|^  npmDepsHash = .*|  npmDepsHash = \"${deps_hash}\";|" \
    packages/rea.nix

  sed -i \
    -e "s|releases/tag/v${current_version}|releases/tag/v${version}|g" \
    -e "s|rea-${current_version}|rea-${version}|g" \
    -e "s|REA ${current_version}|REA ${version}|g" \
    -e "s|./scripts/update.sh ${current_version}|./scripts/update.sh ${version}|g" \
    README.md

  nix fmt packages/rea.nix
  nix flake check --print-build-logs
  nix run . -- --version | grep -Fx "${version}"
  printf 'Updated REA from %s to %s.\n' "$current_version" "$version"
}

main "$@"
