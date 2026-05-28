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

# 暫定 ls/la/ll (eza が無い環境向けフォールバック)。
# eza が mise 経由で入っていれば、後段 (mise activate 以降) で上書きされる。
alias la='ls -A'
alias ll='ls -lah'

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
# ls/tree -> eza (mise activate 後にチェック; 未インストール時は上の素の alias 維持)
# -------------------------
if command -v eza >/dev/null 2>&1; then
  alias ls='eza'
  alias la='eza -a'
  alias ll='eza -lah --git'
  alias tree='eza --tree'
fi

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

# -------------------------
# Helpers
# -------------------------
mkcd() {
  mkdir -p -- "$1" && cd -- "$1"
}

mkcode() {
  mkcd "$1" && code .
}

# -------------------------
# VSCode Remote Tunnel (tmux 常駐)
# -------------------------
# WSL2 では `code` は VSCode Remote 拡張のラッパーで `tunnel` サブコマンドを持たない。
# standalone CLI を ~/.local/bin/code-tunnel として bootstrap.sh で別途インストールする。
# 初回は `code-tunnel tunnel user login --provider github` で認証が必要。
remote-tunnel() {
  local SESSION="remote-tunnel"
  local CMD="$HOME/.local/bin/code-tunnel tunnel --accept-server-license-terms"

  if [ ! -x "$HOME/.local/bin/code-tunnel" ]; then
    echo "code-tunnel が無い。bootstrap.sh を再実行するか、手動でインストールしてください。" >&2
    return 1
  fi

  if ! tmux has-session -t "$SESSION" 2>/dev/null; then
    tmux new-session -d -s "$SESSION" "$CMD"
    echo "tunnel session started."
  else
    echo "tunnel session already running."
  fi
}

# -------------------------
# Machine-local overrides (個人アカウント設定など)
# -------------------------
# ~/.zshrc.local は git 管理外。bootstrap.sh が空ファイルを用意するので
# user.email / SSH 鍵パス / gh アカウント切替などはここに書く。
[ -f "$HOME/.zshrc.local" ] && source "$HOME/.zshrc.local"
