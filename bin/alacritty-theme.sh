#!/usr/bin/env bash
# Dynamic Alacritty-theme + tmux-active-tab-bg switch -- one command
# instead of manually editing alacritty.toml's import line and
# separately re-running a matching `tmux set -g`. Real limitation this
# works around: tmux has no way to query which Alacritty theme is
# currently loaded (no API for that), so nothing can auto-detect this
# on its own -- running this script IS the sync point, by design.
#
# SIMPLIFIED 2026-07-31 (Devin: "native, like how osaka is" -- not a
# hand-picked substitute color): plain 'colour0' for every theme,
# always. An earlier version of this script pulled each theme's real
# [colors.primary].background via Python's tomllib -- technically
# correct, but caused a whole confusing session (Ubuntu's real
# maroon/#300a24 read as near-black at a glance, required literal hex +
# a whole true-color/reattach saga to even render). 'colour0' is always
# safe, never needs re-syncing, and is what Osaka was using from the
# start (its own colour0 happens to equal its real teal, which is why
# it never had any of these problems). Border/cwd accent stays a fixed
# cyan regardless of theme -- see the pane_active_fg/bg block below.
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

ACTIVE_BG='colour0'

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

# Real fix, 2026-07-31: set -g alone (server-wide default) turned out
# not to be enough -- a brand-new session picked it up fine, but an
# EXISTING session (cairn) kept rendering stale even after detach/
# reattach and a full Alacritty restart. Setting it explicitly on
# EVERY currently-running session (not just the global default) covers
# any session that might have its own resolved state, and forcing a
# full client redraw (refresh-client -S) covers any case where a style
# change alone doesn't repaint an already-drawn screen. Devin's ask:
# "can the script just handle all of it" -- this is that, no more
# manual detach/reattach/restart dance required.
if command -v tmux >/dev/null 2>&1 && tmux list-sessions >/dev/null 2>&1; then
    tmux set -g @window_active_bg "$ACTIVE_BG"
    tmux set -g @pane_active_bg "$ACTIVE_BG"
    while IFS= read -r sess; do
        tmux set -t "$sess" @window_active_bg "$ACTIVE_BG" 2>/dev/null || true
        tmux set -t "$sess" @pane_active_bg "$ACTIVE_BG" 2>/dev/null || true
    done < <(tmux list-sessions -F '#{session_name}')
    while IFS= read -r client; do
        tmux refresh-client -S -t "$client" 2>/dev/null || true
    done < <(tmux list-clients -F '#{client_name}')
fi

echo "Switched to $NAME (active-tab bg: $ACTIVE_BG): alacritty.toml import + tmux both updated."
