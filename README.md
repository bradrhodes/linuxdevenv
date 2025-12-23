# Linux Development Environment (Home Manager)

A reproducible development environment for Linux and WSL that replaces the old shell-script installer with a declarative [Home Manager](https://nix-community.github.io/home-manager/) + Flakes setup. This repo installs Fish, Tmux, Neovim (LazyVim), Starship, fonts, tooling, and your dotfiles, and keeps them identical across laptops, servers, and VMs.

App catalog: [APP_CATALOG.yml](APP_CATALOG.yml)

---

## Repo Layout

```
linuxdevenv/
├── README.md                   # This guide
├── bash/                       # Secrets helpers (SOPS/Age)
└── home-manager/
    ├── flake.nix / home.nix    # Main Home Manager configuration
    ├── modules/                # Fish, tmux, starship, git, packages, etc.
    ├── dotfiles/               # Managed dotfiles (fish snippets, tmux.conf, gitconfig…)
    └── install.sh              # First-time installer for any machine
```

The `bash/manage-secrets.sh` + `bash/age-key-setup.sh` scripts manage SOPS/Age secrets. Everything else lives under `home-manager/`.

---

## Requirements

- Linux distro or WSL2 with Git, curl, and sudo access
- [Nix](https://nixos.org) installed (installer handles this if missing)
- Access to the Age bootstrap key (for decrypting secrets)

---

## First-Time Setup on a Machine or VM

1. **Clone the repo**
   ```bash
   git clone git@github.com:<you>/linuxdevenv.git ~/linuxdevenv
   cd ~/linuxdevenv/home-manager
   ```
2. **Install Home Manager config**
   ```bash
   ./install.sh
   ```
   - Installs Nix (if absent) and enables flakes
   - Builds the Home Manager profile defined in this repo
   - Prompts for the SOPS bootstrap key so it can decrypt git user/email
3. **Set Fish as your login shell (once per machine)**
   ```bash
   sudo chsh -s "$(which fish)" "$USER"
   ```
   Log out/in or run `exec fish` after installation.
4. **Add your SSH key to GitHub (optional)** – the activation script writes `~/.ssh/id_ed25519`; copy the public key to GitHub if this machine needs repo access.

> **Tip:** Keep secrets up to date with `bash/manage-secrets.sh edit` whenever you change encrypted values.

---

## Day-to-Day Workflow (Same Machine)

1. **Edit configuration**
   - Packages/apps: update `home-manager/modules/packages.nix`
   - Tool settings: update the relevant module in `home-manager/modules/`
   - Dotfiles: edit the real files in `home-manager/dotfiles/`
2. **Apply changes**
   ```bash
   ~/linuxdevenv/home-manager/apply.sh
   ```
3. **Commit & push** so other machines can pull the same configuration
   ```bash
   cd ~/linuxdevenv
   git status
   git commit -am "Describe change"
   git push
   ```

## Where to Change Things (Quick Reference)

| Task | File(s) |
|------|---------|
| Add/remove packages/apps | `home-manager/modules/packages.nix` |
| Fish plugins/aliases/init | `home-manager/modules/fish.nix`, `home-manager/dotfiles/fish/*` |
| Tmux settings/plugins | `home-manager/modules/tmux.nix`, `home-manager/dotfiles/tmux/*` |
| Git config | `home-manager/modules/git.nix`, `home-manager/dotfiles/git/gitconfig` |
| Starship prompt | `home-manager/modules/starship.nix`, `home-manager/dotfiles/starship.toml` |
| Neovim settings | `home-manager/modules/neovim.nix` |
| Activation tasks (fonts/SSH/LazyVim) | `home-manager/modules/activation.nix` |
| Secrets (git name/email, etc.) | `bash/config/private.yml` via `bash/manage-secrets.sh` |
| Generate app catalog | `home-manager/catalog.sh` → `APP_CATALOG.yml` |

---

## Keeping Multiple Machines in Sync

On each additional machine/VM:

```bash
cd ~/linuxdevenv
git pull
cd home-manager
home-manager switch --flake .
```

As long as every machine points to this repo and runs `home-manager switch`, the installed packages, plugins, fonts, dotfiles, and git settings stay identical. Home Manager tracks generations, so you can run `home-manager switch --rollback` if something breaks.

---

## Managing Packages & Apps

- **Add an app:** add it to `home-manager/modules/packages.nix` under `home.packages`, then run `home-manager switch --flake .`
- **Remove an app:** delete it from `home.packages`, then switch again.
- **Update versions:** run `~/linuxdevenv/home-manager/update.sh`, commit `home-manager/flake.lock`, then switch.
- **Generate catalog:** run `~/linuxdevenv/home-manager/catalog.sh` to refresh `APP_CATALOG.yml`.

If a tool has a dedicated Home Manager module (e.g., Fish, Tmux, Git, Starship), prefer editing its file in `home-manager/modules/` instead of adding ad-hoc config elsewhere.

Because the profile is managed declaratively, you no longer need to re-run setup scripts or track per-machine installations.

---

## Dotfile Management

All managed configs live under `home-manager/dotfiles/` and are symlinked into place by Home Manager:

- `dotfiles/fish/*.fish` → Fish `shellInit` and `interactiveShellInit`
- `dotfiles/git/gitconfig` → `~/.gitconfig` (with `~/.gitconfig.local` holding secret name/email)
- `dotfiles/tmux/*.conf` → tmux main config + plugin snippets
- `dotfiles/starship.toml` → Starship prompt preset

To change a dotfile, edit the real file in the repo, run `home-manager switch`, and commit/push. No quoting or escaping inside Nix expressions.

### Adding a New Dotfile

1. Add the file under `home-manager/dotfiles/` (e.g., `dotfiles/alacritty/alacritty.toml`)
2. Wire it into a module using `home.file` or `xdg.configFile`:
   ```nix
   # Example in a module
   xdg.configFile."alacritty/alacritty.toml".source = ../dotfiles/alacritty/alacritty.toml;
   ```
3. Run `home-manager switch --flake .`

---

## Secrets & Sensitive Config

- `bash/manage-secrets.sh edit` decrypts `bash/config/private.yml` using your Age key.
- Git name/email currently pull from those secrets during activation and write `~/.gitconfig.local`.
- If you add new secrets, keep them in `private.yml` and feed them into modules or activation hooks as needed.

`bash/age-key-setup.sh` handles generating/importing Age keys on new machines.

---

## Removing the Environment from a Machine

Home Manager is user-scoped. To remove everything from a machine:

```bash
home-manager remove
nix profile wipe-history --older-than 30d   # optional cleanup
rm -rf ~/.local/state/nix /nix/var/nix/profiles/per-user/$USER/home-manager
```

Then delete the repo clone if you no longer need it. Secrets remain encrypted in git.

---

## Troubleshooting Checklist

- `home-manager switch --flake . --dry-run` – preview changes
- `home-manager generations` – list past generations for rollback
- `nix flake check` – validate syntax
- `rm ~/.config/fish/conf.d/*-old` – clear stale configs if you previously managed them manually
- For “git tree dirty” warnings during switch, either commit/stash or pass `--no-warn-dirty`

Need more detail on why we switched to Home Manager and how it maps to the old scripts? See `home-manager/HM-MIGRATION.md`.
