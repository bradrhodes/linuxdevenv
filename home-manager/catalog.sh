#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

OUT_FILE="${1:-APP_CATALOG.md}"
TMP_JSON="$(mktemp)"
trap 'rm -f "$TMP_JSON"' EXIT

nix eval --json .#homeConfigurations.bigb.config.home.packages \
  --apply 'pkgs: builtins.map (p: { name = (p.pname or p.name); description = (p.meta.description or ""); }) pkgs' \
  > "$TMP_JSON"

python - "$TMP_JSON" <<'PY' > "$OUT_FILE"
import json
import sys

with open(sys.argv[1], "r", encoding="utf-8") as f:
    data = json.load(f)

data.sort(key=lambda x: x.get("name", ""))

lines = []
lines.append("# Home Manager App Catalog")
lines.append("")
lines.append("Generated from `home.packages` in `home-manager/modules/packages.nix`.")
lines.append("")
lines.append("| Package | Description |")
lines.append("| --- | --- |")

for item in data:
    name = item.get("name", "").strip()
    desc = (item.get("description") or "").replace("\n", " ").strip()
    if not desc:
        desc = "-"
    lines.append(f"| `{name}` | {desc} |")

sys.stdout.write("\n".join(lines))
PY
