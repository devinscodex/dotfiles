# PowerShell profile -- lives outside XDG (Windows has no equivalent),
# same reasoning as home/bashrc-stub. Symlink to $PROFILE (see README).

function prompt {
    $path = $executionContext.SessionState.Path.CurrentLocation.Path
    $home_ = $env:USERPROFILE
    if ($path.StartsWith($home_)) {
        $path = "~" + $path.Substring($home_.Length)
    }

    # Dynamic window/taskbar title -- user@host: path, so multiple
    # Alacritty windows are distinguishable instead of all reading the
    # same static default. Requires dynamic_title = true in alacritty.toml
    # (config/alacritty/alacritty.toml, same repo).
    $host.UI.RawUI.WindowTitle = "$env:USERNAME@$env:COMPUTERNAME`: $path"

    "PS $path$('>' * ($nestedPromptLevel + 1)) "
}
