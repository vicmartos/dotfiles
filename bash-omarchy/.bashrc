# Omarchy environment (OMARCHY_PATH + PATH), needed even for non-interactive shells
[[ -r /usr/share/omarchy/default/bash/env-bootstrap ]] && source /usr/share/omarchy/default/bash/env-bootstrap

# If not running interactively, don't do anything else (leave this above the rc source)
[[ $- != *i* ]] && return

# All the default Omarchy aliases and functions
# (don't mess with these directly, just overwrite them here!)
source "$OMARCHY_PATH/default/bash/rc"

export DOTNET_ROOT="$HOME/.dotnet"
PATH="$HOME/.dotnet:$PATH"
PATH="$PATH:$HOME/.dotnet/tools"
PATH="$PATH:$HOME/.opencode/bin"
PATH="$PATH:$HOME/.local/bin"

if [ -z "$SSH_AUTH_SOCK" ] ; then
  eval `ssh-agent -s`
  ssh-add ~/.ssh/github
fi

alias lg=lazygit
alias hw=herdr-workspacer
# Emacs
# emacsclient does not pass COLORTERM to the daemon, so an xterm-256color
# client frame loses true color even though standalone Emacs supports it.
emacsclient() {
  local arg
  if [[ ${TERM-} == xterm-256color && ${COLORTERM-} == truecolor ]] &&
     infocmp xterm-direct &>/dev/null; then
    for arg in "$@"; do
      if [[ $arg == -t || $arg == --tty ]]; then
        TERM=xterm-direct command emacsclient "$@"
        return
      fi
    done
  fi
  command emacsclient "$@"
}

alias e='emacsclient -t'
alias ec='nohup emacsclient -c -n < /dev/null > /dev/null 2>&1 &'
alias emacsd='systemctl --user status emacs'
alias emacsd-restart='systemctl --user restart emacs'
alias emacsd-stop='systemctl --user stop emacs'
alias emacs-install='emacs -nw'
