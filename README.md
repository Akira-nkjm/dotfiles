# dotfiles

macOS (Apple Silicon) / WSL2 (Ubuntu) / Debian 系 Linux の個人開発環境を 3 ステップで再現する dotfiles。

```bash
git clone https://github.com/Akira-nkjm/dotfiles.git ~/dotfiles
~/dotfiles/bootstrap.sh
exec zsh
```

`bootstrap.sh` は冪等なので、何度走らせても安全。OS は自動判定する (`mac` / `wsl` / `linux`)。

## 構成

| File | 役割 | 反映先 (symlink) |
|---|---|---|
| `bootstrap.sh` | エントリポイント。システムパッケージ (mac: Homebrew / Linux: apt) → rustup → uv → claude/codex → mise → symlink → mise install → docker (Linux) → chsh の順 | (実行のみ) |
| `Brewfile` | macOS の Homebrew レイヤー (シェル統合・システム寄りツール・GUI アプリ・フォント) | (`brew bundle` で使用) |
| `mise-config.toml` | mise の宣言設定 (言語ランタイム + CLI ツール)。全 OS 共通 | `~/.config/mise/config.toml` |
| `zshrc` | シェル設定 (history / completion / aliases / 関数 / mise+zoxide+starship 統合)。冒頭で OS を判定し、OS 固有部分を分岐。末尾で `~/.zshrc.local` を source | `~/.zshrc` |
| `starship.toml` | プロンプト設定 | `~/.config/starship.toml` |
| `gitconfig` | 共有 git 設定 (delta / merge / rebase 等)。マシン固有情報は `~/.gitconfig.local` に分離 | `~/.gitconfig` |

## レイヤー設計

ツール管理は意図的に分業している。mac と Linux で違うのは一番下の「システムパッケージ」層だけ。

| レイヤー | 中身 | 理由 |
|---|---|---|
| **mise** | node / pnpm / go / starship / tmux / gh / ripgrep / fd / bat / jq / just / eza / zoxide / delta / lazygit / yq / typst / terraform / aws-cli / gcloud / gws / kubectl / helm / k9s / k3d / age / sops / ollama | 全 OS で同じ宣言を共有できる、apt / Homebrew より追随が速い、per-project 切替 (`./mise.toml`) が効く |
| **uv** | Python interpreter + packages | uv の `python pin` が速く、mise を挟むと役割が重複する |
| **rustup** | Rust toolchain | rustup の self-update が速い。プロジェクト pin は `rust-toolchain.toml` |
| **claude / codex** | `~/.local/bin/{claude,codex}` (公式 install script、mac / Linux 共通) | 公式推奨。自己更新するので Homebrew / mise を挟まない |
| **Homebrew** (mac) | zsh-autosuggestions / zsh-syntax-highlighting / fzf / git / rsync / syncthing / poppler / xcbeautify / Noto CJK フォント / Nextcloud (`Brewfile`) | シェル統合ファイル・システム寄りのツール・GUI アプリ・フォントは mise の守備範囲外 |
| **apt** (Linux) | zsh / zsh-autosuggestions / zsh-syntax-highlighting / fzf / curl / git / build-essential / pkg-config / libssl-dev | システム基盤、`/usr/share/` のシェル統合ファイルが必要なもの、bootstrap 前提 |
| **docker** (Linux) | Docker Engine (docker-ce / compose-plugin)。公式 apt リポジトリ (ubuntu / debian を自動判定) | デーモン(dockerd)は mise で管理できない。systemd で自動起動 |

同じツールを Homebrew と mise の両方に入れない (PATH の先にある方が使われて混乱する)。

## OS ごとの違い (zshrc)

| 項目 | mac | WSL2 | Linux |
|---|---|---|---|
| プラグインの場所 | `/opt/homebrew/share` | `/usr/share` | `/usr/share` |
| fzf | `fzf --zsh` | apt の examples | apt の examples |
| `open` / `pbcopy` | macOS 標準 | `explorer.exe` / `clip.exe` | (未定義) |
| `ls` の色 | `LSCOLORS` + `LS_COLORS` | `LS_COLORS` | `LS_COLORS` |
| `remote-tunnel` | VSCode アプリの `code tunnel` + `caffeinate` | standalone CLI `code-tunnel` + systemd | 同左 |
| その他 | | remote-cli の PATH 修正、`/usr/lib/wsl/lib` | |

## bootstrap 後の手動ステップ

| 項目 | コマンド |
|---|---|
| git user 情報 (新規マシンの場合のみ) | `git config --file ~/.gitconfig.local user.name "..."` / `user.email "..."` |
| マシン固有のシェル設定 | `~/.zshrc.local` に書く (GitHub アカウント切替関数、SSH 鍵の ssh-add など)。git 管理外 |
| SSH 設定 | `~/.ssh/config` は repo 管理外 (ホスト名や鍵のパスを公開しないため) |
| Claude Code ログイン | `claude` (初回起動でブラウザ認証) |
| OpenAI Codex ログイン | `codex` (初回起動で OpenAI 認証) |
| GitHub CLI ログイン | `gh auth login` |
| Google Cloud SDK ログイン | `gcloud auth login` (gws auth setup が gcloud を呼ぶ前提)。設定は `~/.config/gcloud/` に保存され repo 管理外 |
| Google Workspace CLI ログイン | `gws auth setup` (GCP プロジェクト/OAuth 設定、gcloud 必須) → `gws auth login` (OAuth 同意)。認証情報は `~/.config/gws/` に暗号化保存され repo 管理外 |
| mac: VSCode の `code` コマンド | VSCode のコマンドパレットで「Shell Command: Install 'code' command in PATH」 |
| mac: Docker | Docker Desktop / OrbStack などを手動で入れる |
| WSL2: Windows 側 | VSCode + WSL 拡張は別途手動 (この repo の範囲外) |

## 既存環境からの移行 (mac)

Homebrew で入れていた CLI ツールのうち mise に移したもの (node / pnpm / gh / ripgrep / just / starship / tmux / typst / age / sops / gws など) は、`mise install` の後に `brew uninstall` する。`tree` は `eza --tree` (エイリアス済み) に置き換え。Python は uv で管理する。

## 設計方針

- **mise-centric**: ecosystem-native マネージャ (Corepack 等) より mise-config.toml に集約することを優先。一元管理を取り、エコシステム固有の最適化を捨てる。
- **uv / rustup / claude / codex は例外**: 公式インストーラの自己更新が優秀で公式推奨なものは独立レイヤーに置く。
- **Homebrew / apt / docker も例外**: シェル統合ファイル、GUI アプリ、常駐デーモンは mise では扱えないため、OS ごとのパッケージマネージャに置く。
- **gitconfig 分割**: 共有設定は repo 管理、マシン固有情報 (`user.name` / `user.email` 等) は `~/.gitconfig.local` に分離。`bootstrap.sh` が初回に既存 `~/.gitconfig` を `.local` に退避する。
- **公開 repo**: メールアドレス・内部ホスト名・鍵のパスなどは `~/.zshrc.local` / `~/.gitconfig.local` / `~/.ssh/config` に置き、ここには入れない。

## 動作環境

- macOS (Apple Silicon、Homebrew は `/opt/homebrew`)
- WSL2 (Ubuntu 22.04+)
- Debian 系 Linux (Debian 12+ / Raspberry Pi OS)
