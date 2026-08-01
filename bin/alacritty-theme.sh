#!/usr/bin/env bash
# Dynamic Alacritty-theme + tmux-active-tab-bg switch -- one command
# instead of manually editing alacritty.toml's import line and
# separately re-running a matching `tmux set -g`. Real limitation this
# works around: tmux has no way to query which Alacritty theme is
# currently loaded (no API for that), so nothing can auto-detect this
# on its own -- running this script IS the sync point, by design.
#
# 2026-07-31: pulls each theme's real [colors.primary].background
# straight from its own .toml file (via Python's tomllib) instead of a
# hand-maintained lookup table -- works for ANY theme in the themes/
# folder automatically, not just ones someone remembered to add an
# entry for. See core/lessons/gotchas.md (cairn project, 2026-07-31)
# for why primary.background (not colour0) is the real identity color.
#
# Usage: alacritty-theme.sh <name>     switch to <name> (partial match
#                                      OK, e.g. "osaka" matches
#                                      solarized_osaka.toml)
#        alacritty-theme.sh            show current theme
set -euo pipefail
ALACRITTY_TOML="/mnt/c/Users/devin/AppData/Roaming/alacritty/alacritty.toml"
THEMES_DIR="/mnt/c/Users/devin/AppData/Roaming/alacritty/themes"

current_theme() {
    grep -oP '^\s*"themes/\K[^"]+(?=\.toml")' "$ALACRITTY_TOML" | head -1
}

if [ $# -eq 0 ]; then
    echo "Current alacritty.toml import: themes/$(current_theme).toml"
    exit 0
fi

QUERY="$1"
QUERY="${QUERY%.toml}"
QUERY="${QUERY#themes/}"

# Exact match first, then substring (case-insensitive) so "osaka"
# reaches solarized_osaka.toml without needing the full name.
MATCHES=()
if [ -f "$THEMES_DIR/$QUERY.toml" ]; then
    MATCHES=("$QUERY")
else
    while IFS= read -r -d '' f; do
        base="$(basename "$f" .toml)"
        MATCHES+=("$base")
    done < <(find "$THEMES_DIR" -maxdepth 1 -iname "*${QUERY}*.toml" -print0)
fi

if [ "${#MATCHES[@]}" -eq 0 ]; then
    echo "No theme matching '$QUERY' found in $THEMES_DIR" >&2
    exit 1
elif [ "${#MATCHES[@]}" -gt 1 ]; then
    echo "Ambiguous -- '$QUERY' matches multiple themes, be more specific:" >&2
    printf '  %s\n' "${MATCHES[@]}" >&2
    exit 1
fi
NAME="${MATCHES[0]}"

# Real identity color: [colors.primary].background from the theme's own
# file. Falls back to 'colour0' (always safe, never wrong, just maybe
# not that theme's true brand color) if the theme doesn't define one --
# some minimal theme files don't set colors.primary explicitly.
ACTIVE_BG=$(python3 - "$THEMES_DIR/$NAME.toml" <<'PYEOF'
import sys
import tomllib

with open(sys.argv[1], "rb") as f:
    data = tomllib.load(f)
bg = data.get("colors", {}).get("primary", {}).get("background")
print(bg if bg else "colour0")
PYEOF
)

python3 - "$ALACRITTY_TOML" "themes/$NAME.toml" <<'PYEOF'
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

tmux set -g @window_active_bg "$ACTIVE_BG"
tmux set -g @pane_active_bg "$ACTIVE_BG"

echo "Switched to $NAME (active-tab bg: $ACTIVE_BG): alacritty.toml import + tmux both updated."
