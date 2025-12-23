# Repository Guidelines

## Project Structure & Module Organization

- `home-manager/`: Home Manager flake and configuration.
- `home-manager/home.nix`: root config importing modules.
- `home-manager/modules/`: per-tool modules (packages, fish, tmux, git, neovim, starship, activation, sops).
- `home-manager/dotfiles/`: real config files symlinked into place.
- `home-manager/install.sh`: first-time setup entry point.
- `bash/`: SOPS/Age helpers only (`manage-secrets.sh`, `age-key-setup.sh`, `scripts/logging.sh`).

## Build, Test, and Development Commands

- `~/linuxdevenv/home-manager/install.sh`: first-time install on a machine; installs Nix if needed and runs the flake.
- `~/linuxdevenv/home-manager/apply.sh`: apply current config (`home-manager switch --flake .`).
- `~/linuxdevenv/home-manager/update.sh`: update flake inputs then apply.
- `~/linuxdevenv/home-manager/catalog.sh`: generate `home-manager/APP_CATALOG.md` from `home.packages`.
- `nix flake check` (optional): validate flake syntax.

## Coding Style & Naming Conventions

- Nix: follow existing formatting (2-space indentation, short inline comments, grouped sections).
- Shell: follow existing style (set `-euo pipefail`, clear logging, avoid heavy magic).
- Dotfiles: keep literal configs in `home-manager/dotfiles/` rather than embedding in Nix.
- Prefer descriptive module names (e.g., `modules/tmux.nix`) and keep each module single-purpose.

## Testing Guidelines

- No automated test suite in this repo.
- Validate changes by running `home-manager switch --flake .` and checking expected tool configs.

## Commit & Pull Request Guidelines

- Commit style observed in history: sentence-case, past-tense messages (e.g., “Added glow to my install”).
- Keep commits focused; update `README.md` when workflow changes.
- PRs should describe user-facing changes, include any new commands, and link issues if applicable.

## Security & Secrets

- Secrets live in `bash/config/private.yml` and are managed with SOPS/Age.
- Use `bash/manage-secrets.sh edit` to modify secrets; never commit decrypted files.

## Agent Instructions

- For non-trivial requests, present a plan before making changes.
- Ask clarifying questions when any requirement is ambiguous or has multiple valid interpretations.
- Ask for permission before starting implementation of an approved plan.
*** End Patch"}]}{"recipient_name":"functions.apply_patch","parameters":{}}
