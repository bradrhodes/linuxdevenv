# Complete Comparison: Old Scripts vs Home Manager

This document maps **every function** from `bootstrap.sh` and `dev-env-setup.sh` to the new Home Manager approach.

---

## bootstrap.sh - Prerequisites Installation

| Function | What It Did | Home Manager Equivalent | Status |
|----------|-------------|------------------------|--------|
| **Install git** | Installs git via package manager | Included in Nix (dependency) | ✅ Automatic |
| **Install curl** | Installs curl for downloads | `home.packages = [ pkgs.curl ]` or activation scripts use it | ✅ Automatic |
| **Install unzip** | Installs unzip for archives | Already in `home.nix` (line 43) | ✅ Covered |
| **Install SOPS** | Secret management tool | **NOT in home.nix** | ⚠️ **MISSING** |
| **Install yq** | YAML processor (Go version) | **NOT in home.nix** | ⚠️ **MISSING** |
| **Install age** | Encryption tool for SOPS | **NOT in home.nix** | ⚠️ **MISSING** |
| **Install optional tools** | wget, vim, nano, less, ca-certificates | Can add to `home.nix` if needed | ⏭️ Optional |

### ⚠️ Action Required
**Your `install.sh` is missing critical tools for secrets management!**

---

## dev-env-setup.sh - Main Setup Functions

| Function | What It Did | Home Manager Equivalent | Status |
|----------|-------------|------------------------|--------|
| **Load config (SOPS)** | Decrypt private.yml and load vars | **Not handled by HM** | ⚠️ **Need separate workflow** |
| **Extend sudo** | Keep sudo alive during setup | Not needed (HM doesn't require sudo) | ✅ Not needed |

---

## setup_nix() - Nix Installation

| Function | What It Did | Home Manager Equivalent | Status |
|----------|-------------|------------------------|--------|
| **Install Nix** | Install Nix via Determinate Systems | Done by `install.sh` (line 37) | ✅ Covered |
| **Install Nix packages** | Install packages from `nix_packages` list | All in `home.nix` (lines 19-48) | ✅ Covered |

---

## setup_linux_packages() - apt/dnf/etc Packages

| Function | What It Did | Home Manager Equivalent | Status |
|----------|-------------|------------------------|--------|
| **Install build-essential** | gcc, make, binutils, etc. | `home.nix` has gcc, gnumake, binutils (lines 33, 43-44) | ✅ Covered |
| **Distro-specific packages** | Install via apt/dnf/pacman/etc. | **All via Nix now** (distro-agnostic) | ✅ Better approach |

---

## setup_homebrew() - Homebrew Packages

| Function | What It Did | Home Manager Equivalent | Status |
|----------|-------------|------------------------|--------|
| **Install Homebrew** | Install brew on Linux | **Not needed** (packages in Nix) | ✅ Obsolete |
| **Install uv** | Python package manager | `home.nix` line 40 | ✅ Covered |
| **Install lazygit** | Git TUI | `home.nix` line 41 | ✅ Covered |

---

## setup_fish_shell() - Fish Shell Setup

| Function | What It Did | Home Manager Equivalent | Status |
|----------|-------------|------------------------|--------|
| **Install Fish** | Install fish shell | `home.nix` line 20 | ✅ Covered |
| **Set default shell** | `chsh -s $(which fish)` | User must do manually after HM switch | ⚠️ **Manual step** |
| **Install Fisher** | Fish plugin manager | **Not needed** (HM manages plugins) | ✅ Better approach |
| **Install plugins** | bass, z, autopair, fzf | `programs.fish.plugins` (lines 58-84) | ✅ Covered |
| **Configure aliases** | Set up shell aliases | `programs.fish.shellAliases` (lines 98-103) | ✅ Covered |
| **Init Starship** | Configure prompt | `programs.fish.interactiveShellInit` (lines 87-95) | ✅ Covered |

---

## setup_fonts() - Nerd Fonts

| Function | What It Did | Home Manager Equivalent | Status |
|----------|-------------|------------------------|--------|
| **Download Nerd Font** | Download from GitHub releases | `home.activation.installNerdFont` (lines 221-236) | ✅ Covered |
| **Install to ~/.local/share/fonts** | Extract and install fonts | Same activation script | ✅ Covered |
| **Run fc-cache** | Refresh font cache | Same activation script | ✅ Covered |

---

## setup_neovim() - Neovim Setup

| Function | What It Did | Home Manager Equivalent | Status |
|----------|-------------|------------------------|--------|
| **Install Neovim** | Install via Nix | `home.nix` line 26 | ✅ Covered |
| **Install NvChad** | Clone NvChad config | **Script had this, but you switched to LazyVim** | ⚠️ Note |
| **Install LazyVim** | Clone LazyVim starter | `home.activation.installLazyVim` (lines 210-218) | ✅ Covered |
| **Set as default editor** | Configure EDITOR env var | `programs.neovim.defaultEditor = true` (line 180) | ✅ Covered |

---

## setup_tmux() - TMUX Setup

| Function | What It Did | Home Manager Equivalent | Status |
|----------|-------------|------------------------|--------|
| **Install TMUX** | Install tmux package | HM installs it (when `programs.tmux.enable = true`) | ✅ Covered |
| **Set prefix key** | Configure C-a prefix | `programs.tmux.prefix = "C-a"` (line 109) | ✅ Covered |
| **Install TPM** | TMUX Plugin Manager | **Not needed** (HM manages plugins) | ✅ Better approach |
| **Install plugins** | sensible, resurrect, continuum | `programs.tmux.plugins` (lines 114-132) | ✅ Covered |
| **Generate tmux.conf** | Create config file | HM generates it automatically | ✅ Covered |

---

## setup_git() - Git Configuration

| Function | What It Did | Home Manager Equivalent | Status |
|----------|-------------|------------------------|--------|
| **Set user.name** | From private.yml via SOPS | Commented out in `home.nix` (line 156) | ⚠️ **Need to uncomment & populate** |
| **Set user.email** | From private.yml via SOPS | Commented out in `home.nix` (line 157) | ⚠️ **Need to uncomment & populate** |
| **Set signing key** | GPG key for commits | Commented out in `home.nix` (lines 158-159) | ⏭️ Optional |
| **Git aliases** | Shortcuts like `st`, `co` | `programs.git.aliases` (lines 168-174) | ✅ Covered |
| **Git config** | init.defaultBranch, pull.rebase | `programs.git.extraConfig` (lines 161-166) | ✅ Covered |

---

## setup_ssh() - SSH Key Generation

| Function | What It Did | Home Manager Equivalent | Status |
|----------|-------------|------------------------|--------|
| **Generate SSH key** | Create ed25519 key if needed | **NOT in home.nix** | ❌ **MISSING** |
| **Set passphrase** | Optional key passphrase | **NOT in home.nix** | ❌ **MISSING** |
| **Add to ssh-agent** | Start agent and add key | **NOT in home.nix** | ❌ **MISSING** |
| **Set permissions** | chmod 700 ~/.ssh | **NOT in home.nix** | ❌ **MISSING** |

---

## setup_github() - GitHub SSH Integration

| Function | What It Did | Home Manager Equivalent | Status |
|----------|-------------|------------------------|--------|
| **Upload SSH key** | Use GitHub API to add key | **NOT in home.nix** | ❌ **MISSING** |
| **Test connection** | `ssh -T git@github.com` | **NOT in home.nix** | ❌ **MISSING** |

---

## setup_chezmoi() - Dotfiles Management

| Function | What It Did | Home Manager Equivalent | Status |
|----------|-------------|------------------------|--------|
| **Install chezmoi** | Install via Nix | `home.nix` line 50 | ✅ Covered |
| **Init chezmoi repo** | Clone dotfiles repo | **NOT in home.nix** | ⚠️ Can add to activation |
| **Apply dotfiles** | Run `chezmoi apply` | **NOT in home.nix** | ⚠️ Can add to activation |

---

## Summary: What's Missing

### 🔴 Critical (Need to Add)

1. **SOPS/Age/yq tools** - Required for secrets management
   ```nix
   home.packages = with pkgs; [
     sops
     age
     yq-go  # The Go version of yq
   ];
   ```

2. **SSH key generation** - Need activation script or manual process
3. **Git secrets** - Need to uncomment and populate from private.yml

### 🟡 Important (Recommended to Add)

4. **GitHub SSH key upload** - Optional but useful automation
5. **Chezmoi initialization** - If you want to keep using chezmoi
6. **Manual step reminder** - Change default shell to Fish

### 🟢 Optional (Nice to Have)

7. **Python tools setup** - `uv` installed, but not configured for Python 3.12
8. **Starship preset** - Currently basic config, not using pastel-powerline preset

---

## Recommended Actions

### 1. Update install.sh to include secrets tools

Add at the top of `install.sh` before calling Home Manager:

```bash
# Install SOPS, Age, and yq if not present (needed for secrets)
if ! command -v sops &> /dev/null || ! command -v age &> /dev/null || ! command -v yq &> /dev/null; then
    log_info "Installing secrets management tools..."
    nix profile install nixpkgs#sops nixpkgs#age nixpkgs#yq-go
fi
```

### 2. Add secrets tools to home.nix

```nix
home.packages = with pkgs; [
  # ... existing packages
  sops
  age
  yq-go
];
```

### 3. Add SSH key generation to home.nix

Add to `home.activation`:
```nix
generateSSHKey = config.lib.dag.entryAfter ["writeBoundary"] ''
  SSH_DIR="$HOME/.ssh"
  SSH_KEY="$SSH_DIR/id_ed25519"

  if [ ! -f "$SSH_KEY" ]; then
    $DRY_RUN_CMD mkdir -p "$SSH_DIR"
    $DRY_RUN_CMD chmod 700 "$SSH_DIR"
    $DRY_RUN_CMD ${pkgs.openssh}/bin/ssh-keygen -t ed25519 -f "$SSH_KEY" -N ""
    echo "Generated SSH key at $SSH_KEY"
  fi
'';
```

### 4. Document the manual steps

Update README.md to include:
- `sudo chsh -s $(which fish) $USER` after first install
- How to load Git secrets from private.yml
- How to upload SSH key to GitHub

---

## What You Can Delete After Migration

Once fully migrated to Home Manager, you can archive:

- ✅ `bash/scripts/nix-setup.sh` - replaced
- ✅ `bash/scripts/fish-setup.sh` - replaced
- ✅ `bash/scripts/tmux-setup.sh` - replaced
- ✅ `bash/scripts/brew-setup.sh` - replaced
- ✅ `bash/scripts/linux-package-manager-setup.sh` - replaced
- ✅ `bash/scripts/fonts-setup.sh` - replaced
- ✅ `bash/scripts/neovim-setup.sh` - replaced
- ⚠️ `bash/scripts/git-setup.sh` - can integrate into HM
- ⚠️ `bash/scripts/ssh-setup.sh` - can integrate into HM
- ⚠️ `bash/scripts/github-setup.sh` - can integrate into HM
- ⚠️ `bash/scripts/chezmoi-setup.sh` - if you drop chezmoi
- ✅ Keep: `bash/scripts/manage-secrets.sh` - still useful
- ✅ Keep: `bash/age-key-setup.sh` - still useful
- ✅ Keep: `bash/bootstrap.sh` - can be used as alternative to install.sh
