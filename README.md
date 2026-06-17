# dotfiles

WSL2 (Ubuntu) 上の個人開発環境を 3 ステップで再現する dotfiles。

```bash
git clone https://github.com/Akira-nkjm/dotfiles.git ~/dotfiles
~/dotfiles/bootstrap.sh
exec zsh
```

`bootstrap.sh` は冪等なので、何度走らせても安全。

## 構成

| File | 役割 | 反映先 (symlink) |
|---|---|---|
| `bootstrap.sh` | エントリポイント。apt → rustup → uv → claude/codex → mise → symlink → mise install → docker → chsh の順 | (実行のみ) |
| `mise-config.toml` | mise の宣言設定 (言語ランタイム + CLI ツール) | `~/.config/mise/config.toml` |
| `zshrc` | シェル設定 (history / completion / aliases / 関数 / mise+zoxide+starship 統合)。末尾で `~/.zshrc.local` を source | `~/.zshrc` |
| `starship.toml` | プロンプト設定 | `~/.config/starship.toml` |
| `gitconfig` | 共有 git 設定 (delta / merge / rebase 等)。マシン固有情報は `~/.gitconfig.local` に分離 | `~/.gitconfig` |

## レイヤー設計

ツール管理は意図的に 5 層に分業:

| レイヤー | 中身 | 理由 |
|---|---|---|
| **apt** | zsh / zsh-autosuggestions / zsh-syntax-highlighting / fzf / curl / git / build-essential / pkg-config / libssl-dev | システム基盤、`/usr/share/` のシェル統合ファイルが必要なもの、bootstrap 前提 |
| **rustup** | Rust toolchain | rustup の self-update が速い。プロジェクト pin は `rust-toolchain.toml` |
| **uv** | Python interpreter + packages | uv の `python pin` が速く、mise を挟むと役割が重複する |
| **claude / codex** | `~/.local/bin/{claude,codex}` (公式 install script) | Anthropic / OpenAI の native installer が公式推奨。Claude は自己更新 |
| **mise** | 他全部: node / pnpm / starship / tmux / gh / ripgrep / fd / bat / jq / just / eza / zoxide / delta / lazygit / yq / terraform / aws-cli | 一元管理、apt より追随が速い、per-project 切替 (`./mise.toml`) が効く |
| **docker** | Docker Engine (docker-ce / compose-plugin)。公式 apt リポジトリ | デーモン(dockerd)は mise で管理できない。WSL2 は systemd=true なので systemctl で自動起動 |

## bootstrap 後の手動ステップ

| 項目 | コマンド |
|---|---|
| git user 情報 (新規マシンの場合のみ) | `git config --file ~/.gitconfig.local user.name "..."` / `user.email "..."` |
| Claude Code ログイン | `claude` (初回起動でブラウザ認証) |
| OpenAI Codex ログイン | `codex` (初回起動で OpenAI 認証) |
| GitHub CLI ログイン | `gh auth login` |
| Windows 側 | VSCode + WSL 拡張は別途手動 (この repo の範囲外) |

## 設計方針

- **mise-centric**: ecosystem-native マネージャ (Corepack 等) より mise-config.toml に集約することを優先。一元管理を取り、エコシステム固有の最適化を捨てる。
- **uv / rustup / claude / codex は例外**: 公式インストーラの自己更新が優秀で公式推奨なものは独立レイヤーに置く。
- **docker も例外**: 常駐デーモン(dockerd)は mise(バイナリ管理)では扱えないため、公式 apt リポジトリで独立レイヤーに置く。CLI 単体ツール(terraform / aws-cli)は mise に集約。
- **gitconfig 分割**: 共有設定は repo 管理、マシン固有情報 (`user.name` / `user.email` 等) は `~/.gitconfig.local` に分離。`bootstrap.sh` が初回に既存 `~/.gitconfig` を `.local` に退避する。

## 動作環境

- WSL2 (Ubuntu 22.04+ 想定)
- 他ディストリ・素の Linux では apt 部分の調整が必要
