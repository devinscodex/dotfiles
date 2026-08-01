#!/usr/bin/env bash
# Dynamic Alacritty-theme + tmux-active-tab-bg switch -- one command
# instead of two manual edits. Real limitation this works around: tmux
# has no way to query which Alacritty theme is currently loaded (no
# API for that), so nothing can auto-detect this on its own -- running
# this script IS the sync point, by design, not a workaround for a bug.
#
# Add a new theme: add a case entry below with its REAL active-bg
# identity color -- read Alacritty's [colors.primary].background from
# the actual theme file (~/AppData/Roaming/alacritty/themes/<name>.toml
# on Windows), never guess it. colour0 ([colors.normal].black) is a
# DIFFERENT value that often has no relationship to the real
# background at all -- see core/lessons/gotchas.md (cairn project,
# 2026-07-31) for why that distinction matters here.
#
# Usage: alacritty-theme.sh <name>     switch to <name>
#        alacritty-theme.sh            show current + list known names
set -euo pipefail
ALACRITTY_TOML="/mnt/c/Users/devin/AppData/Roaming/alacritty/alacritty.toml"

declare -A ACTIVE_BG=(
    [osaka]='colour0'      # solarized_osaka: colour0 IS its real black (#073642), a genuine dark teal
    [ubuntu]='#300a24'     # ubuntu: colour0 is unrelated charcoal (#2e3436) -- literal hex needed
)
declare -A IMPORT_LINE=(
    [osaka]='themes/solarized_osaka.toml'
    [ubuntu]='themes/ubuntu.toml'
)

if [ $# -eq 0 ]; then
    current=$(grep -oP '^\s*"themes/\K[^"]+(?=\.toml")' "$ALACRITTY_TOML" | head -1)
    echo "Current alacritty.toml import: themes/${current}.toml"
    echo "Known names: ${!ACTIVE_BG[*]}"
    exit 0
fi

NAME="$1"
if [ -z "${ACTIVE_BG[$NAME]:-}" ]; then
    echo "Unknown theme: $NAME (known: ${!ACTIVE_BG[*]})" >&2
    exit 1
fi

python3 - "$ALACRITTY_TOML" "${IMPORT_LINE[$NAME]}" <<'PYEOF'
import re
import sys

path, target = sys.argv[1], sys.argv[2]
with open(path, encoding="utf-8") as f:
    lines = f.readlines()

out = []
found = False
for line in lines:
    m = re.match(r'^(\s*)#?\s*"(themes/[^"]+\.toml)"(.*)$', line)
    if not m:
        out.append(line)
        continue
    indent, theme_path, rest = m.groups()
    if theme_path == target:
        out.append(f'{indent}"{theme_path}"{rest}\n')
        found = True
    else:
        stripped = line.lstrip()
        if not stripped.startswith("#"):
            out.append(f'{indent}#"{theme_path}"{rest}\n')
        else:
            out.append(line)

if not found:
    sys.exit(f"theme line for {target!r} not found in {path} -- add it to the import list first")

with open(path, "w", encoding="utf-8") as f:
    f.writelines(out)
PYEOF

tmux set -g @window_active_bg "${ACTIVE_BG[$NAME]}"
tmux set -g @pane_active_bg "${ACTIVE_BG[$NAME]}"

echo "Switched to $NAME: alacritty.toml import + tmux active-tab bg both updated (live_config_reload picks up the Alacritty side instantly)."
