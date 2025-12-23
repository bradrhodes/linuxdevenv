#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$SCRIPT_DIR"

OUT_FILE="${1:-$REPO_ROOT/APP_CATALOG.yml}"
TMP_FILE="$(mktemp)"
trap 'rm -f "$TMP_FILE"' EXIT

nix eval --json .#homeConfigurations.bigb.config.home.packages \
  --apply '
    pkgs:
    let
      items = builtins.map (p: {
        name = (p.pname or p.name);
        description = builtins.replaceStrings ["\n"] [" "] (p.meta.description or "");
      }) pkgs;
      sorted = builtins.sort (a: b: a.name < b.name) items;
    in
    {
      meta = {
        title = "Home Manager App Catalog";
        source = "home.packages (home-manager/modules/packages.nix)";
      };
      packages = sorted;
    }
  ' | yq -P > "$TMP_FILE"

if [ -f "$OUT_FILE" ] && cmp -s "$TMP_FILE" "$OUT_FILE"; then
  echo "Catalog unchanged: $OUT_FILE"
else
  mv "$TMP_FILE" "$OUT_FILE"
  echo "Catalog updated: $OUT_FILE"
fi
