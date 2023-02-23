#  ____, ____,
# (-|  \(-|  \
#  _|__/ _|__/
# Devin Dwight's bash config...
# ...its a combination of bits of pieces of others' configs, including the kali prompt.

# if not running interactively, don't do anything
[[ $- != *i* ]] && return

####  EXPORTS  ####
export TERM="xterm-256color"
export PATH="/home/picard/scripts/:$PATH"
export PATH="/opt/:$PATH"
export PATH="/opt/scripts/:$PATH"			# this is where I keep personal scripts at
export PATH="/usr/bin/env/:$PATH"			# for zenmap...and prolly others...
export MANPAGER=less 						# default (changed it before & messed it up)


#### HISTORY MGMT ####

export HISTTIMEFORMAT="%y%m%d_%T - "
export HISTCONTROL=ignoredups:erasedups		# no duplicate entries
shopt -s histappend  # do not overwrite history
HISTSIZE=100000
HISTFILESIZE=10000000



####  ALIASES  ####

alias ls='ls -lhGF --color=auto'
alias ld='LC_COLLATE=C ls -alF'
alias cls='clear'
# interactive files:
alias rm='trash -iv'
alias cp="cp -iv"
alias mv='mv -iv'

# application aliases
alias obsd='obsidian'
alias python='python3'
alias rr='ranger'

# Micro
alias install-micro='curl https://getmic.ro | bash && sudo mv micro /opt'
alias nano='micro'

# Nala - "apt" overlay
alias get-nala-repo='echo "deb http://deb.volian.org/volian/ scar main" | sudo tee /etc/apt/sources.list.d/volian-archive-scar-unstable.list; wget -qO - https://deb.volian.org/volian/scar.key | sudo tee /etc/apt/trusted.gpg.d/volian-archive-scar-unstable.gpg'
alias install-nala='sudo nala install nala'
apt() { 
  command nala "$@"
}
sudo() {
  if [ "$1" = "apt" ]; then
    shift
    command sudo nala "$@"
  else
    command sudo "$@"
  fi
}



# ignore upper and lowercase when TAB completion...
bind "set completion-ignore-case on"

####  SHOPT  ####
shopt -s autocd # change to named directory
shopt -s cdspell # autocorrects cd misspellings
shopt -s cmdhist # save multi-line commands in history as single line
shopt -s dotglob
shopt -s histappend # do not overwrite history
shopt -s expand_aliases # expand aliases
shopt -s checkwinsize # checks term size when bash regains control


#### PROMPT HANDLING ####
case "$TERM" in
	xterm-color|*-256) color_prompt=yes;;
esac
force_color_prompt=yes

if [ -n "$force_color_prompt" ]; then
    if [ -x /usr/bin/tput ] && tput setaf 1 >&/dev/null; then
	color_prompt=yes
    else
	color_prompt=
    fi
fi

if [ "$color_prompt" = yes ]; then
    prompt_color='\[\033[;32m\]'
    info_color='\[\033[1;34m\]'
    prompt_symbol=" @ "
    if [ "$EUID" -eq 0 ]; then # Change prompt colors for root user
	prompt_color='\[\033[;94m\]'
	info_color='\[\033[1;31m\]'
	prompt_symbol=💀
    fi
    PS1=$prompt_color'┌──${debian_chroot:+($debian_chroot)──}('$info_color'\u${prompt_symbol}\h'$prompt_color')-[\[\033[0;1m\]\w'$prompt_color']\n'$prompt_color'└─'$info_color'\$\[\033[0m\] '   
else
    PS1='${debian_chroot:+($debian_chroot)}\u@\h:\w\$ '
fi
unset color_prompt force_color_prompt

# If this is an xterm set the title to user@host:dir
case "$TERM" in
xterm*|rxvt*)
    PS1="\[\e]0;${debian_chroot:+($debian_chroot)}\u@\h: \w\a\]$PS1"
    ;;
*)
    ;;
esac

if [ -x /usr/bin/dircolors ]; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"

    alias grep='grep --color=auto'
    alias fgrep='fgrep --color=auto'
    alias egrep='egrep --color=auto'
    alias diff='diff --color=auto'
    alias ip='ip --color=auto'

    export LESS_TERMCAP_mb=$'\E[1;31m'     # begin blink
    export LESS_TERMCAP_md=$'\E[1;36m'     # begin bold
    export LESS_TERMCAP_me=$'\E[0m'        # reset bold/blink
    export LESS_TERMCAP_so=$'\E[01;33m'    # begin reverse video
    export LESS_TERMCAP_se=$'\E[0m'        # reset reverse video
    export LESS_TERMCAP_us=$'\E[1;32m'     # begin underline
    export LESS_TERMCAP_ue=$'\E[0m'        # reset underline
fi

