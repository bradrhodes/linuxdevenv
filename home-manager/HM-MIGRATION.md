# Home Manager Migration Overview

This document captures the intent, scope, and moving parts of the shift from the script-driven setup (`bash/` directory) to the declarative Home Manager configuration in `home-manager/`.

## Goals of the Migration

1. **Single Source of Truth** – keep packages, plugins, and dotfiles in git so every machine converges to the same state.
2. **Idempotent & Safe** – be able to rerun `home-manager switch` at any time without worrying about “already installed” logic or partial installs.
3. **Cross-Distro Consistency** – rely on Nix packages instead of distro-specific package managers or Homebrew.
4. **Simpler Dotfile Workflow** – edit regular config files (Fish, tmux, Starship, Git) inside the repo rather than inline strings or templated shell heredocs.
5. **Keep Secrets Secure** – continue using SOPS + Age for git credentials and private data while letting Home Manager read those values during activation.

## Architecture at a Glance

- **Nix Flake (`home-manager/flake.nix`)** pins exact versions of `nixpkgs`, `home-manager`, and `sops-nix`.
- **Home Configuration (`home-manager/home.nix`)** imports modular pieces for fish, tmux, git, packages, secrets, activation tasks, etc.
- **Modules (`home-manager/modules/`)** each own one concern (fish, tmux, starship, git, packages, activation hooks).
- **Dotfiles (`home-manager/dotfiles/`)** hold the literal config files that Home Manager symlinks into place.
- **Activation Hooks** reproduce script-only behaviors (LazyVim bootstrap, Nerd Font install, SSH key generation) in an idempotent way.
- **Legacy Scripts (`bash/`)** remain for secrets management and historical reference but no longer drive package installation.

## Key Components Replacing the Old Scripts

| Old Script | New Home Manager Source | Notes |
|------------|------------------------|-------|
| `bash/bootstrap.sh` (pkg install) | `home-manager/modules/packages.nix` | All tooling comes from Nix packages now. |
| `bash/scripts/fish-setup.sh` | `modules/fish.nix` + `dotfiles/fish/` | Plugins declared in Nix; init logic lives in real Fish files. |
| `bash/scripts/tmux-setup.sh` + TPM | `modules/tmux.nix` + `dotfiles/tmux/` | Plugins managed declaratively, no TPM needed. |
| `bash/scripts/neovim-setup.sh` | `programs.neovim` + activation LazyVim clone | Automatically installs LazyVim starter repo. |
| `bash/scripts/fonts-setup.sh` | `modules/activation.nix` (installNerdFont) | Downloads EnvyCodeR Nerd Font once. |
| `bash/scripts/git-setup.sh` | `modules/git.nix` + secrets hook | Git config tracked as a dotfile; user/email pulled from SOPS. |
| `bash/scripts/ssh-setup.sh` | `activation.nix` (generateSSHKey) | Generates ed25519 key if missing. |
| `starship preset` heredoc | `dotfiles/starship.toml` | Native Starship TOML file tracked in git. |
| Chezmoi templates | `home-manager/dotfiles/` | Home Manager symlinks the files directly. |

## What Stayed External

- **Secrets Workflow** – `bash/manage-secrets.sh` and `bash/age-key-setup.sh` still create/manage Age keys and the encrypted `private.yml`. Home Manager reads the decrypted values during activation but does not replace the existing workflow.
- **GitHub SSH Upload** – still a manual step; activation shows the public key for you to copy.
- **Bootstrap Script** – kept for historical purposes, but new machines should use `home-manager/install.sh`.

## Operational Flow

1. **Authoring Changes**
   - Edit `home-manager/home.nix`, module files, or any dotfile under `home-manager/dotfiles/`.
   - For secrets-backed values (e.g., git user/email), update `bash/config/private.yml` via `manage-secrets.sh`.
2. **Apply Locally** – run `home-manager switch --flake /mnt/c/dev/linuxdevenv/home-manager`.
3. **Commit & Push** – keep both Nix expressions and dotfiles in git.
4. **Other Machines** – `git pull` + `home-manager switch` to converge.

## Benefits Realized

- **Deterministic environments** – identical tools, plugins, fonts, and configs everywhere.
- **Rollback** – `home-manager switch --rollback` restores a previous generation instantly.
- **Readable configs** – real Fish/tmux/Git/Starship files instead of embedded heredocs.
- **Less tooling sprawl** – no TPM/Fisher/chezmoi/Homebrew required.
- **Safer secrets** – SOPS files remain encrypted; only activation-time hooks read the decrypted data.

Refer back to this file whenever you need to explain the “why” behind the new setup or map a legacy script to its Home Manager replacement.
