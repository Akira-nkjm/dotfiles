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

# just のレシピ名を動的補完（アクティブな justfile / import 先から取得）
command -v just >/dev/null && source <(just --completions zsh)

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


#-------------------------
# GitHub CLI token export (gh auth token の出力を環境変数に)
#-------------------------

export GITHUB_PERSONAL_ACCESS_TOKEN=$(gh auth token)

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

  # systemd サービス (`code-tunnel tunnel service install`) で常駐済みなら二重起動しない。
  # 既にトンネルが Connected ならここで打ち切る (過去に手動起動と重複して不調になった)。
  if "$HOME/.local/bin/code-tunnel" tunnel status 2>/dev/null | grep -q '"Connected"'; then
    echo "tunnel は既に起動済み (systemd service もしくは別セッション)。何もしない。" >&2
    return 0
  fi

  if ! tmux has-session -t "$SESSION" 2>/dev/null; then
    tmux new-session -d -s "$SESSION" "$CMD"
    echo "tunnel session started."
  else
    echo "tunnel session already running."
  fi
}

# tunnel を systemd ユーザーサービスとして常駐登録する (初回一度だけ手動で実行)。
# install は冪等 (再実行で re-install)。初回は GitHub/Microsoft のデバイスコード認証あり。
# linger を有効化して WSL 起動と同時 (ログインセッション無しでも) 立ち上がるようにする。
remote-tunnel-install() {
  if [ ! -x "$HOME/.local/bin/code-tunnel" ]; then
    echo "code-tunnel が無い。bootstrap.sh を再実行するか、手動でインストールしてください。" >&2
    return 1
  fi
  "$HOME/.local/bin/code-tunnel" tunnel service install --accept-server-license-terms || return 1
  sudo loginctl enable-linger "$USER"
  echo "登録完了。状態: 'code-tunnel tunnel status' / 'systemctl --user status code-tunnel.service'"
}

# -------------------------
# `code` を remote-cli 側に固定 (Remote-WSL / SSH / Tunnel セッション中のみ)
# -------------------------
# Remote セッション中は /mnt/c/.../Microsoft VS Code/bin/code が PATH 先頭に
# 居座り、`code .` が手元の VSCode ウィンドウではなく WSL ホスト上の Code.exe を
# 起動してしまう。VSCODE_IPC_HOOK_CLI が立っているとき = リモートセッション中なので、
# その時だけ VSCode が自動設置した remote-cli を PATH 先頭に挿し直す。
if [ -n "$VSCODE_IPC_HOOK_CLI" ]; then
  for _cli_dir in \
    "$HOME"/.vscode-server/bin/*/bin/remote-cli(N) \
    "$HOME"/.vscode/cli/servers/*/server/bin/remote-cli(N)
  do
    if [ -x "$_cli_dir/code" ]; then
      export PATH="$_cli_dir:$PATH"
      break
    fi
  done
  unset _cli_dir
fi

# -------------------------
# WSL2 で Windows 側の DLL を PATH に追加 (WSL2 固有の問題回避)
# -------------------------
export PATH="$PATH:/usr/lib/wsl/lib"

# -------------------------
# Machine-local overrides (個人アカウント設定など)
# -------------------------
# ~/.zshrc.local は git 管理外。bootstrap.sh が空ファイルを用意するので
# user.email / SSH 鍵パス / gh アカウント切替などはここに書く。
[ -f "$HOME/.zshrc.local" ] && source "$HOME/.zshrc.local"
