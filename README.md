# dotfiles

Personal config, plain files + symlinks. No install framework, no
templating -- suckless in the literal sense: read a file, know exactly
what it does.

## Layout

```
config/    -> $XDG_CONFIG_HOME (~/.config)
home/      -> $HOME (files that must live outside XDG, e.g. bashrc-stub)
bin/       -> anywhere on PATH (~/.local/bin)
```

Bash itself doesn't know about XDG paths, so `home/bashrc-stub` is the
one real `~/.bashrc` -- it just sets `XDG_CONFIG_HOME` and sources the
actual config at `config/bash/bashrc`.

## Setup

Symlink what you want, e.g.:

```sh
ln -s "$PWD/home/bashrc-stub" ~/.bashrc
ln -s "$PWD/config/bash" ~/.config/bash
ln -s "$PWD/config/tmux" ~/.config/tmux
ln -s "$PWD/config/alacritty" ~/.config/alacritty   # Linux/WSL path;
                                                     # on Windows this
                                                     # goes in
                                                     # %appdata%/alacritty
ln -s "$PWD/bin/alacritty-theme.sh" ~/.local/bin/alacritty-theme.sh
```

## Alacritty themes

`config/alacritty/themes/` bundles the full
[alacritty-theme](https://github.com/alacritty/alacritty-theme)
community pack plus 8 custom family themes (`slate_*`, `bonepaper_*`,
`flexoki_*`, `martin_*`) sourced from
[devs-themes](https://github.com/devinscodex/devs-themes), the
canonical palette repo shared with Slate/Runestone/webUI.

`bin/alacritty-theme.sh <name>` switches the active theme (partial
name match, e.g. `alacritty-theme.sh osaka`) and keeps tmux's
active-tab color in sync in every running session -- one command
instead of hand-editing `alacritty.toml`'s import line and separately
re-running a matching `tmux set -g`.

## tmux

`config/tmux/tmux.conf` -- vi-style pane binds, true-color enabled,
theme-aware active/inactive pane and tab colors (see the file's own
comments for the per-color rationale).
