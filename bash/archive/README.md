# Archived Scripts

This directory contains bash scripts that are no longer actively used, as their functionality has been replaced by the Home Manager configuration in `../home-manager/`.

## Archived on: 2025-11-26

These scripts were archived when the project migrated from bash-based setup scripts to declarative Nix Home Manager configuration.

## Archived Scripts

### `scripts/`

- **`nix-setup.sh`** - Replaced by Home Manager flake
- **`fish-setup.sh`** - Replaced by `home-manager/modules/fish.nix`
- **`tmux-setup.sh`** - Replaced by `home-manager/modules/tmux.nix`
- **`fonts-setup.sh`** - Replaced by activation script in `home-manager/modules/activation.nix`
- **`neovim-setup.sh`** - Replaced by `home-manager/modules/neovim.nix`
- **`brew-setup.sh`** - No longer needed (all packages via Nix)
- **`linux-package-manager-setup.sh`** - No longer needed (all packages via Nix)
- **`chezmoi-setup.sh`** - Chezmoi now managed via Home Manager

### Root Scripts

- **`dev-env-setup.sh`** - Main orchestrator script, replaced by `home-manager/install.sh`

### Config

- **`config/public.yml`** - Configuration file replaced by `home.nix` and modules

## Still Active Scripts

The following scripts in `../` are still actively used:

- **`bootstrap.sh`** - Alternative installer, can coexist with Home Manager
- **`manage-secrets.sh`** - Still used for SOPS/Age secrets management
- **`scripts/age-key-setup.sh`** - Still used for Age key management
- **`scripts/git-setup.sh`** - May integrate with Home Manager later
- **`scripts/ssh-setup.sh`** - May integrate advanced features later
- **`scripts/github-setup.sh`** - May integrate API upload later
- **`scripts/load-config.sh`** - Utility functions
- **`scripts/logging.sh`** - Utility functions

## Why These Were Archived

With the migration to Home Manager:

1. **Declarative Configuration**: All package installation and configuration is now declared in Nix files
2. **Idempotency**: Home Manager compares desired vs actual state, only changes what's needed
3. **Cross-Platform**: Same configuration works on any Linux distro (no more distro-specific scripts)
4. **Rollback Support**: Can easily rollback to previous configurations
5. **Version Control**: All configuration is in git-tracked `.nix` files

## If You Need to Reference These

These scripts can still be useful as reference for:
- Understanding the old workflow
- Extracting specific configuration details
- Comparing old vs new approaches

## Restoring from Archive

If you need to restore any of these scripts:

```bash
# From the bash directory
git mv archive/scripts/SCRIPTNAME.sh scripts/
# or
git mv archive/dev-env-setup.sh .
```

## See Also

- `../home-manager/README.md` - New Home Manager workflow
- `../home-manager/MIGRATION.md` - Detailed migration guide
- `../home-manager/COMPARISON.md` - Line-by-line comparison
