# macOS の Homebrew レイヤー (`brew bundle --file ~/dotfiles/Brewfile`)。
# Linux の apt レイヤーに相当する。CLI ツールは原則 mise-config.toml 側に置き、
# ここには mise で扱えない / 扱わないほうがいいものだけを書く。

# --- シェル統合 (zshrc が $(brew --prefix)/share から source する) ---
brew "zsh-autosuggestions"
brew "zsh-syntax-highlighting"
brew "fzf"            # `fzf --zsh` でキーバインドを読み込む

# --- システム寄りのツール ---
brew "git"            # Apple 同梱の git より新しいもの
brew "rsync"          # macOS 同梱は古い。フルディスクアクセスをこの rsync に付けて使う場合あり
brew "poppler"        # pdftotext など (ライブラリ + CLI)
brew "xcbeautify"     # Xcode のビルドログ整形

# --- GUI アプリ / フォント ---
cask "font-noto-sans-cjk-jp"
cask "font-noto-serif-cjk-jp"
cask "nextcloud"
# Syncthing はアプリ版 (formula + brew services ではなく)。アプリが自己更新するので、
# ~/Documents などへのアクセス許可が更新のたびに外れない (formula は Cellar のパスが変わって外れる)。
# 「Start at login」はメニューバーの Syncthing → Preferences で設定する。
cask "syncthing-app"
