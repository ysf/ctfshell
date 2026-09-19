autoload -U colors && colors

[[ -r ~/code/znap/znap.zsh ]] ||
    git clone --depth 1 -- https://github.com/marlonrichert/zsh-snap.git ~/code/znap

source ~/code/znap/znap.zsh  # Start Znap

export EDITOR='nvim'
export TOOLS_DIR="$HOME/tools"

[ -d "~/bin" ] && export PATH="~/bin:$PATH"
[ -d "$TOOLS_DIR/bin" ] && export PATH="$TOOLS_DIR/bin:$PATH"
[ -d "$TOOLS_DIR" ] && export PATH="$TOOLS_DIR:$PATH"
[ -d "/opt/binja-debugger/bin" ] && export PATH="/opt/binja-debugger/bin:/opt/binja-debugger/plugins/lldb/bin:$PATH"
[ -d "/opt/binja-debugger/plugins" ] && export LD_LIBRARY_PATH="/opt/binja-debugger/plugins:/opt/binja-debugger/plugins/lldb/lib:$LD_LIBRARY_PATH"

export HISTSIZE=10000
export SAVEHIST=10000
export HISTFILE="/mnt/persistent/.config/zsh/.zsh_history"

setopt HIST_EXPIRE_DUPS_FIRST
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_IGNORE_SPACE
setopt HIST_FIND_NO_DUPS
setopt HIST_SAVE_NO_DUPS
setopt INC_APPEND_HISTORY
setopt SHARE_HISTORY

fpath+=$HOME/.config/zsh/pure
autoload -U promptinit; promptinit
prompt pure

if [ -f ~/.zsh_aliases ]; then
    source ~/.zsh_aliases
fi

source <(fzf --zsh)

autoload -U compinit
compinit
