# -------------------------
# History
# -------------------------
HISTFILE=~/.zsh_history
HISTSIZE=100000
SAVEHIST=100000

setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_SPACE
setopt SHARE_HISTORY
setopt INC_APPEND_HISTORY
setopt HIST_FIND_NO_DUPS

# -------------------------
# Completion
# -------------------------
autoload -Uz compinit && compinit
zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'
[[ -n "$LS_COLORS" ]] && zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}

# -------------------------
# Key bindings
# -------------------------
bindkey -e

# -------------------------
# PATH
# -------------------------
export PATH="$HOME/.local/bin:$PATH"   # uv, mise, etc.

# -------------------------
# Aliases
# -------------------------
alias ..="cd .."
alias ...="cd ../.."
alias reload="source ~/.zshrc"

# ls/tree -> eza (mise で導入。未インストール時はそのまま素の ls にフォールバック)
if command -v eza >/dev/null 2>&1; then
  alias ls='eza'
  alias la='eza -a'
  alias ll='eza -lah --git'
  alias tree='eza --tree'
else
  alias la='ls -A'
  alias ll='ls -lah'
fi

# WSL2 -> Windows
alias open="explorer.exe"
alias pbcopy="clip.exe"

# -------------------------
# Rust / Cargo
# -------------------------
[ -f "$HOME/.cargo/env" ] && source "$HOME/.cargo/env"

# -------------------------
# mise (optional)
# -------------------------
command -v mise >/dev/null 2>&1 && eval "$(mise activate zsh)"

# -------------------------
# Plugins (apt package paths)
# -------------------------
[ -f /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh ] && \
  source /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh

# -------------------------
# fzf (Ctrl+R / Ctrl+T / Alt+C)
# -------------------------
[ -f /usr/share/doc/fzf/examples/key-bindings.zsh ] && \
  source /usr/share/doc/fzf/examples/key-bindings.zsh
[ -f /usr/share/doc/fzf/examples/completion.zsh ] && \
  source /usr/share/doc/fzf/examples/completion.zsh

# -------------------------
# zoxide (smart cd: `z foo` で頻出 dir にジャンプ)
# -------------------------
command -v zoxide >/dev/null 2>&1 && eval "$(zoxide init zsh)"

# -------------------------
# Prompt (Starship)
# -------------------------
command -v starship >/dev/null 2>&1 && eval "$(starship init zsh)"

# -------------------------
# Syntax highlighting (must be sourced last)
# -------------------------
[ -f /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ] && \
  source /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
