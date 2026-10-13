# -------------------------
# OS 判定
# -------------------------
# mac / wsl / linux の 3 種類。OS 固有の設定はこの変数で分岐する。
case "$(uname -s)" in
  Darwin) DOTFILES_OS=mac ;;
  Linux)
    if [[ -n "$WSL_DISTRO_NAME" ]] || grep -qi microsoft /proc/version 2>/dev/null; then
      DOTFILES_OS=wsl
    else
      DOTFILES_OS=linux
    fi
    ;;
  *) DOTFILES_OS=other ;;
esac

# zsh プラグイン / fzf の置き場所 (mac: Homebrew, Linux: apt)
if [[ $DOTFILES_OS == mac ]] && [[ -d /opt/homebrew/share ]]; then
  ZSH_PLUGIN_DIR=/opt/homebrew/share
else
  ZSH_PLUGIN_DIR=/usr/share
fi

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
# Colors (ls / eza / 補完候補)
# -------------------------
# LS_COLORS は GNU ls・eza・zsh の補完候補一覧が読む (GNU 形式)
export LS_COLORS="di=1;34:ln=1;36:so=1;35:pi=33:ex=1;32:bd=1;33:cd=1;33:su=37;41:sg=30;43:tw=1;34:ow=1;34"
if [[ $DOTFILES_OS == mac ]]; then
  # macOS の BSD ls は CLICOLOR で色を有効化し、LSCOLORS で色を決める (上と同じ配色)
  #   順番: dir, symlink, socket, pipe, exec, block, char, setuid, setgid, sticky+o+w, o+w
  #   a=黒 b=赤 c=緑 d=茶 e=青 f=マゼンタ g=シアン h=白 / 大文字=太字 / x=標準
  export CLICOLOR=1
  export LSCOLORS="ExGxFxdxCxDxDxhbadExEx"
fi

# -------------------------
# Completion
# -------------------------
fpath=(~/.zfunc $fpath)
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
export PATH="$HOME/.local/bin:$PATH"   # uv, mise, claude, codex, etc.

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

# WSL2 -> Windows (mac / 素の Linux では open・pbcopy を上書きしない)
if [[ $DOTFILES_OS == wsl ]]; then
  alias open="explorer.exe"
  alias pbcopy="clip.exe"
fi

# -------------------------
# Rust / Cargo
# -------------------------
[ -f "$HOME/.cargo/env" ] && source "$HOME/.cargo/env"

# -------------------------
# gcloud が使う Python
# -------------------------
# gcloud は Python 3.10+ が必要。mac の /usr/bin/python3 は 3.9 なので、
# bootstrap.sh が uv で入れる Python 3.13 を使わせる (mise の gcloud も同じ)。
_uv_py=( "$HOME"/.local/share/uv/python/cpython-3.13-*/bin/python3.13(N) )
(( ${#_uv_py} )) && export CLOUDSDK_PYTHON="${_uv_py[1]}"
unset _uv_py

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
# Plugins (mac: Homebrew / Linux: apt)
# -------------------------
[ -f "$ZSH_PLUGIN_DIR/zsh-autosuggestions/zsh-autosuggestions.zsh" ] && \
  source "$ZSH_PLUGIN_DIR/zsh-autosuggestions/zsh-autosuggestions.zsh"

# -------------------------
# fzf (Ctrl+R / Ctrl+T / Alt+C)
# -------------------------
# fzf 0.48+ は `fzf --zsh` で統合スクリプトを出力できる (Homebrew 版はこれ)。
# apt の fzf は古いので /usr/share/doc/fzf/examples から読む。
if command -v fzf >/dev/null 2>&1 && fzf --zsh >/dev/null 2>&1; then
  source <(fzf --zsh)
else
  [ -f /usr/share/doc/fzf/examples/key-bindings.zsh ] && \
    source /usr/share/doc/fzf/examples/key-bindings.zsh
  [ -f /usr/share/doc/fzf/examples/completion.zsh ] && \
    source /usr/share/doc/fzf/examples/completion.zsh
fi

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
[ -f "$ZSH_PLUGIN_DIR/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" ] && \
  source "$ZSH_PLUGIN_DIR/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"

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
# 注意: シェルから起動する全プロセスにトークンが渡る。必要なツールだけに渡すなら
# `GITHUB_PERSONAL_ACCESS_TOKEN=$(gh auth token) <command>` の形にする。
command -v gh >/dev/null 2>&1 && export GITHUB_PERSONAL_ACCESS_TOKEN=$(gh auth token 2>/dev/null)

# -------------------------
# VSCode Remote Tunnel (tmux 常駐)
# -------------------------
if [[ $DOTFILES_OS == mac ]]; then
  # mac: VSCode アプリの `code` CLI が tunnel を持つ。caffeinate でスリープを防ぐ。
  remote-tunnel() {
    local SESSION="remote-tunnel"
    local CMD="/usr/bin/caffeinate -imsu -- code tunnel --accept-server-license-terms"

    if ! command -v code >/dev/null 2>&1; then
      echo "code が無い。VSCode のコマンドパレットで 'Shell Command: Install code command in PATH' を実行してください。" >&2
      return 1
    fi

    if ! tmux has-session -t "$SESSION" 2>/dev/null; then
      tmux new-session -d -s "$SESSION" "$CMD"
      echo "tunnel session started."
    else
      echo "tunnel session already running."
    fi
  }
else
  # WSL2 / Linux: `code` は VSCode Remote 拡張のラッパーで `tunnel` サブコマンドを持たない。
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
fi

# -------------------------
# WSL2 固有
# -------------------------
if [[ $DOTFILES_OS == wsl ]]; then
  # `code` を remote-cli 側に固定 (Remote-WSL / SSH / Tunnel セッション中のみ)。
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

  # Windows 側の DLL を PATH に追加 (WSL2 固有の問題回避)
  export PATH="$PATH:/usr/lib/wsl/lib"
fi

# -------------------------
# Machine-local overrides (個人アカウント設定など)
# -------------------------
# ~/.zshrc.local は git 管理外。bootstrap.sh が空ファイルを用意するので
# user.email / SSH 鍵パス / gh アカウント切替などはここに書く。
[ -f "$HOME/.zshrc.local" ] && source "$HOME/.zshrc.local"
