#  ____, ____,
# (-|  \(-|  \
#  _|__/ _|__/
# Devin Dwight's bash config...not much to see here; pretty standard stuff
# after any changes to this file, run "exec bash" to restart shell & apply changes

####  EXPORTS  ####
export TERM="xterm-256color"
export PATH="/opt/scripts/:$PATH"			# this is where I keep personal scripts at
export PATH="~/ansible/scripts/:$PATH"      # ansible scripts
export PATH="/home/devin/.cargo/bin:$PATH"	# contains EXA (replacement for LS)
export MANPAGER=less 						# default (changed it before & messed it up)

# History management
export HISTTIMEFORMAT="%y%m%d_%T - "
export HISTCONTROL=ignoredups:erasedups		# no duplicate entries
shopt -s histappend  # do not overwrite history
HISTSIZE=100000
HISTFILESIZE=10000000

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

####  SHOPT  ####
shopt -s autocd # change to named directory
shopt -s cdspell # autocorrects cd misspellings
shopt -s cmdhist # save multi-line commands in history as single line
shopt -s dotglob
shopt -s histappend # do not overwrite history
shopt -s expand_aliases # expand aliases
shopt -s checkwinsize # checks term size when bash regains control

#ignore upper and lowercase when TAB completion
bind "set completion-ignore-case on"

####  ALIASES  ####

# Changing "ls" to "exa"
alias ls='exa -alhG --no-permissions --no-user --group-directories-first' # my preferred listing
alias la='exa -a --color=always --group-directories-first'  # all files and dirs
alias ll='exa -l --color=always --group-directories-first'  # long format
alias lt='exa -aT --color=always --group-directories-first' # tree listing
alias l.='exa -a | egrep "^\."'

# Colorize grep output (good for log files)
alias grep='grep --color=auto'
alias egrep='egrep --color=auto'
alias fgrep='fgrep --color=auto'

# confirm before overwriting something
alias rm='trash -iv'
alias cp="cp -iv"
alias mv='mv -iv'

# faster clear screen
alias cls='clear'

# APT to Nala (better package mgmt)
alias apt='nala'

# nano to micro
alias nano='micro'
alias snano='sudo micro'

### SETTING THE STARSHIP PROMPT ###
eval "$(starship init bash)"
