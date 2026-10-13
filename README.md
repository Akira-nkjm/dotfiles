# dotfiles

Personal dev environment for macOS (Apple Silicon), WSL2 (Ubuntu) and Debian-based Linux.

```bash
git clone https://github.com/Akira-nkjm/dotfiles.git ~/dotfiles
~/dotfiles/bootstrap.sh
exec zsh
```

`bootstrap.sh` detects the OS (`mac` / `wsl` / `linux`) and is safe to re-run.

## Files

| File | Purpose | Linked to |
|---|---|---|
| `bootstrap.sh` | Installs everything below and creates the symlinks | — |
| `Brewfile` | Homebrew packages (macOS only) | — |
| `mise-config.toml` | Language runtimes and CLI tools (all OSes) | `~/.config/mise/config.toml` |
| `zshrc` | Shell config; OS-specific parts are branched at the top | `~/.zshrc` |
| `starship.toml` | Prompt | `~/.config/starship.toml` |
| `gitconfig` | Shared git config; includes `~/.gitconfig.local` | `~/.gitconfig` |

## Layers

| Layer | What | Why |
|---|---|---|
| mise | node, pnpm, go, gh, ripgrep, eza, zoxide, starship, tmux, kubectl, helm, age, sops, ... | One declaration for every OS; per-project versions |
| uv / rustup | Python / Rust toolchains | Fast official self-updaters |
| claude / codex | Official installers into `~/.local/bin` | Recommended upstream; they self-update |
| Homebrew (mac) | zsh plugins, fzf, git, rsync, syncthing, fonts, GUI apps | Shell integration files and apps mise doesn't handle |
| apt (Linux) | zsh, zsh plugins, fzf, build tools | Same, on Linux |
| Docker (Linux) | Docker Engine from the official apt repo | Daemon; on macOS install Docker Desktop / OrbStack manually |

Don't install the same tool through both Homebrew and mise.

## Machine-local settings (not in this public repo)

- `~/.zshrc.local` — account switchers, `ssh-add`, anything with personal info
- `~/.gitconfig.local` — `user.name`, `user.email`
- `~/.ssh/config`

## After bootstrap

- Log in: `gh auth login`, `claude`, `codex`, `gcloud auth login`, `gws auth setup && gws auth login`
- macOS: install the `code` command from VSCode ("Shell Command: Install 'code' command in PATH")
- macOS migration: `brew uninstall` the CLI tools that now come from mise
