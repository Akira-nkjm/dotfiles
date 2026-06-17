#!/usr/bin/env bash
# WSL2 (Ubuntu) bootstrap — automates the steps documented in ~/wsl2-setup.md.
# Idempotent: safe to run multiple times.
#
# Usage:
#   git clone <this repo> ~/dotfiles
#   ~/dotfiles/bootstrap.sh
#   exec zsh

set -euo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

log() { printf '\n\033[1;36m==>\033[0m %s\n' "$*"; }

# -------------------------
# 1. apt packages
# -------------------------
# 方針: apt にはシステム基盤のみ残す。言語ランタイム・CLI ツールは mise (後述) で管理。
#   - zsh: ログインシェル本体 (chsh で /etc/shells 経由)
#   - zsh-autosuggestions / zsh-syntax-highlighting: /usr/share から source するため apt 必須
#   - fzf: zshrc が /usr/share/doc/fzf/examples/ のキーバインドを source するため apt 必須
#   - curl / git: mise や rustup を入れる前提
#   - build-essential / pkg-config / libssl-dev: ネイティブ拡張のビルド用
log "apt update / upgrade / install"
sudo apt update
sudo apt upgrade -y
sudo apt install -y \
  zsh \
  zsh-autosuggestions \
  zsh-syntax-highlighting \
  fzf \
  curl \
  git \
  build-essential \
  pkg-config \
  libssl-dev

# -------------------------
# 2. rustup
# -------------------------
if ! command -v rustc >/dev/null 2>&1; then
  log "Installing rustup"
  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
fi
# shellcheck disable=SC1091
[ -f "$HOME/.cargo/env" ] && source "$HOME/.cargo/env"

# -------------------------
# 3. uv (Python package manager)
# -------------------------
if ! command -v uv >/dev/null 2>&1; then
  log "Installing uv"
  curl -LsSf https://astral.sh/uv/install.sh | sh
fi

# -------------------------
# 4. AI coding assistants (Claude Code / OpenAI Codex CLI)
# -------------------------
# 公式 install script を使う。理由:
#   - Anthropic / OpenAI ともに native installer が公式推奨で、npm 版は Advanced 扱い
#   - Claude Code はバックグラウンドで自己更新する (mise を挟むとこれが効きにくい)
#   - 設置先 ~/.local/bin/ は zshrc の PATH に既に通っている
if ! command -v claude >/dev/null 2>&1; then
  log "Installing Claude Code (~/.local/bin/claude)"
  curl -fsSL https://claude.ai/install.sh | bash
fi

if ! command -v codex >/dev/null 2>&1; then
  log "Installing OpenAI Codex CLI (~/.local/bin/codex)"
  curl -fsSL https://chatgpt.com/codex/install.sh | sh
fi

# VSCode CLI standalone (zshrc の remote-tunnel 関数が使う ~/.local/bin/code-tunnel)
# 注: VSCode Remote 拡張が PATH に注入する `code` は tunnel サブコマンドを持たないため、
# 別名 code-tunnel として standalone CLI を入れる。
if [ ! -x "$HOME/.local/bin/code-tunnel" ]; then
  log "Installing VSCode CLI standalone (~/.local/bin/code-tunnel)"
  mkdir -p "$HOME/.local/bin"
  tmp=$(mktemp -d)
  curl -fsSL "https://update.code.visualstudio.com/latest/cli-linux-x64/stable" \
    -o "$tmp/code-cli.tar.gz"
  tar -xzf "$tmp/code-cli.tar.gz" -C "$tmp"
  mv "$tmp/code" "$HOME/.local/bin/code-tunnel"
  chmod +x "$HOME/.local/bin/code-tunnel"
  rm -rf "$tmp"
fi

# -------------------------
# 5. mise (language / CLI tool manager)
# -------------------------
# starship / tmux / node / pnpm / gh / ripgrep / fd / bat / jq / just / eza /
# zoxide / delta / lazygit / yq は mise-config.toml で宣言し、後段の
# `mise install` でまとめて入れる。
if ! command -v mise >/dev/null 2>&1 && [ ! -x "$HOME/.local/bin/mise" ]; then
  log "Installing mise"
  curl https://mise.run | sh
fi

# -------------------------
# 6. dotfiles symlinks
# -------------------------
log "Linking config files"
mkdir -p "$HOME/.config"

backup() {
  local p="$1"
  if [ -e "$p" ] && [ ! -L "$p" ]; then
    local b="${p}.bak.$(date +%Y%m%d%H%M%S)"
    echo "  backup $p -> $b"
    mv "$p" "$b"
  fi
}

backup "$HOME/.zshrc"
ln -sfn "$DOTFILES/zshrc" "$HOME/.zshrc"

# ~/.zshrc.local: マシン固有の個人設定 (gh アカウント切替, SSH 鍵 path 等) を入れる空ファイル。
# dotfiles/zshrc の末尾で source される。git 管理外。
[ -f "$HOME/.zshrc.local" ] || touch "$HOME/.zshrc.local"

backup "$HOME/.config/starship.toml"
ln -sfn "$DOTFILES/starship.toml" "$HOME/.config/starship.toml"

mkdir -p "$HOME/.config/mise"
backup "$HOME/.config/mise/config.toml"
ln -sfn "$DOTFILES/mise-config.toml" "$HOME/.config/mise/config.toml"

# gitconfig: 既存の ~/.gitconfig (user.name / user.email) を ~/.gitconfig.local に退避してから
# 共有設定 (dotfiles/gitconfig) をシンボリックリンクする。dotfiles/gitconfig 側は
# [include] path = ~/.gitconfig.local でマシン固有情報を読み込む。
if [ -f "$HOME/.gitconfig" ] && [ ! -L "$HOME/.gitconfig" ]; then
  if [ ! -f "$HOME/.gitconfig.local" ]; then
    log "Moving existing ~/.gitconfig -> ~/.gitconfig.local (machine-specific user info)"
    mv "$HOME/.gitconfig" "$HOME/.gitconfig.local"
  else
    backup "$HOME/.gitconfig"
  fi
fi
[ -f "$HOME/.gitconfig.local" ] || touch "$HOME/.gitconfig.local"
ln -sfn "$DOTFILES/gitconfig" "$HOME/.gitconfig"

# -------------------------
# 7. mise install (global tools)
# -------------------------
if [ -x "$HOME/.local/bin/mise" ]; then
  log "Installing tools declared in ~/.config/mise/config.toml"
  "$HOME/.local/bin/mise" install
fi

# -------------------------
# 8. Docker Engine (LocalStack 等のコンテナ基盤)
# -------------------------
# 方針: mise はデーモン(dockerd)を管理できないため Docker は独立レイヤー。
# Docker 公式 apt リポジトリを使う(Ubuntu 同梱版より追随が速く公式推奨)。
# WSL2 は systemd=true (/etc/wsl.conf) なので systemctl で自動起動できる。
if ! command -v docker >/dev/null 2>&1; then
  log "Installing Docker Engine (official apt repo)"
  sudo install -m 0755 -d /etc/apt/keyrings
  sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
    -o /etc/apt/keyrings/docker.asc
  sudo chmod a+r /etc/apt/keyrings/docker.asc
  echo \
    "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] \
https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" \
    | sudo tee /etc/apt/sources.list.d/docker.list >/dev/null
  sudo apt update
  sudo apt install -y docker-ce docker-ce-cli containerd.io \
    docker-buildx-plugin docker-compose-plugin
fi
# sudo なしで docker を使う: docker グループに追加(反映は再ログイン後)
if ! id -nG "$USER" | grep -qw docker; then
  log "Adding $USER to docker group (re-login required to take effect)"
  sudo usermod -aG docker "$USER"
fi
# systemd 有効なら起動 + 自動起動を有効化
if [ -d /run/systemd/system ]; then
  sudo systemctl enable --now docker
fi

# -------------------------
# 9. default shell -> zsh
# -------------------------
zsh_path="$(command -v zsh)"
current_shell="$(getent passwd "$USER" | cut -d: -f7)"
if [ "$current_shell" != "$zsh_path" ]; then
  log "Changing default shell to $zsh_path (requires password)"
  chsh -s "$zsh_path"
fi

log "Done. Open a new shell or run: exec zsh"
