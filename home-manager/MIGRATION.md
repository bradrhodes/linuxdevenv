# Migration Guide: From Bash Scripts to Home Manager

This guide explains the transition from the bash script-based setup to Home Manager with Flakes.

## 🎯 What Changed

### Package Management
**Before:**
- Ran `./dev-env-setup.sh` once to install packages
- Manual re-run needed after config changes
- Multiple package managers (Nix, Brew, apt)

**After:**
- Edit `home-manager/home.nix` to add/remove packages
- Run `home-manager switch` to apply (idempotent)
- **All packages now via Nix** (no more brew/apt needed)

### Configuration Management
**Before:**
- `bash/config/public.yml` - YAML config file
- Bash scripts parse YAML and generate configs
- Configs created once during setup

**After:**
- `home-manager/home.nix` - Nix config file
- Home Manager generates configs declaratively
- **Every `switch` regenerates configs** (always in sync)

### Plugin Management
**Before:**
- Fisher for Fish plugins
- TPM for Tmux plugins
- Manual installation

**After:**
- Fish plugins declared in `programs.fish.plugins`
- Tmux plugins declared in `programs.tmux.plugins`
- **No plugin managers needed** (HM handles it)

### Dotfiles
**Before:**
- Chezmoi for dotfile management
- Separate tool/workflow

**After:**
- Home Manager manages dotfiles directly
- Can phase out chezmoi eventually

---

## ✅ What Stayed the Same

### Secrets Management
- **SOPS + Age still work exactly as before**
- Keep using `./manage-secrets.sh` for private.yml
- Can integrate with Home Manager via sops-nix (optional)

### Git Workflow
- Your git repo workflow is unchanged
- Still commit and push changes
- Still pull on other machines

### Cross-Distro Support
- **Still works on any Linux distro**
- Even better - Nix handles all packages now
- No more distro-specific package lists

---

## 📋 Your New Workflow

### Adding a New Application

**Example: Add `jq` (JSON processor)**

1. Edit config:
```nix
# home-manager/home.nix
home.packages = with pkgs; [
  ripgrep
  bat
  jq        # ← add this
];
```

2. Apply:
```bash
cd ~/linuxdevenv/home-manager
home-manager switch
```

3. Commit:
```bash
git add home.nix
git commit -m "Add jq package"
git push
```

### Changing Configuration

**Example: Change Fish shell alias**

1. Edit config:
```nix
# home-manager/home.nix
programs.fish = {
  shellAliases = {
    ll = "eza -la";
    cat = "bat";
    myalias = "echo hello";  # ← add alias
  };
};
```

2. Apply:
```bash
home-manager switch
```

Your `~/.config/fish/config.fish` is regenerated with the new alias.

### On a New Machine

**Option 1: Fresh Install**
```bash
# 1. Install Nix (if not already installed)
curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install

# 2. Clone your repo
git clone <your-repo> ~/linuxdevenv
cd ~/linuxdevenv/home-manager

# 3. Build and activate
nix run home-manager/master -- switch --flake .

# 4. Fish will be installed but not set as default shell yet
# To change your default shell:
sudo chsh -s $(which fish) $USER
```

**Option 2: Use old bootstrap (still works)**
```bash
./bootstrap.sh
cd home-manager
home-manager switch --flake .
```

### Trying New Distros

The workflow is **identical on every distro**:

```bash
# On Ubuntu, Fedora, Arch, etc.
curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install
git clone <your-repo> ~/linuxdevenv
cd ~/linuxdevenv/home-manager
nix run home-manager/master -- switch --flake .
```

---

## 🔑 Key Differences to Remember

| Aspect | Old Way | New Way |
|--------|---------|---------|
| **Installing apps** | Add to public.yml → run script | Add to home.nix → `switch` |
| **Changing config** | Edit files manually | Edit home.nix → `switch` |
| **Idempotency** | Scripts check "already installed" | HM always safe to run |
| **Rollback** | Manual/git revert | `home-manager generations` |
| **Package sources** | Nix + Brew + apt | Just Nix |
| **Secrets** | SOPS (unchanged) | SOPS (unchanged) |

---

## 🚀 Advanced Features You Get

### Rollback to Previous Generation
```bash
# List generations
home-manager generations

# Rollback to previous
home-manager switch --rollback

# Switch to specific generation
/nix/store/xxx-home-manager-generation/activate
```

### Dry Run (See What Would Change)
```bash
home-manager switch --dry-run
```

### Clean Old Generations
```bash
nix-collect-garbage -d
```

---

## 🔧 Integrating Secrets (Optional)

Your current SOPS workflow can stay as-is, but you can optionally integrate it:

```nix
# In flake.nix, add sops-nix input
inputs.sops-nix.url = "github:Mic92/sops-nix";

# In home.nix
imports = [ inputs.sops-nix.homeManagerModules.sops ];

sops = {
  age.keyFile = "~/.config/sops/age/keys.txt";
  defaultSopsFile = ../bash/config/private.yml;

  secrets.git-username = {};
  secrets.git-email = {};
};

programs.git = {
  userName = config.sops.secrets.git-username.path;
  userEmail = config.sops.secrets.git-email.path;
};
```

**Note:** This is optional. Your current `manage-secrets.sh` works fine.

---

## 📦 What Can Be Removed Eventually

Once you're comfortable with Home Manager:

- ❌ `bash/scripts/nix-setup.sh` - replaced by flake
- ❌ `bash/scripts/fish-setup.sh` - replaced by `programs.fish`
- ❌ `bash/scripts/tmux-setup.sh` - replaced by `programs.tmux`
- ❌ `bash/scripts/brew-setup.sh` - no longer needed
- ❌ `bash/scripts/linux-package-manager-setup.sh` - no longer needed
- ❌ `bash/config/public.yml` - replaced by `home.nix`
- ⚠️ `bash/scripts/git-setup.sh` - can integrate into HM
- ⚠️ `bash/scripts/ssh-setup.sh` - can integrate into HM
- ✅ `bash/scripts/manage-secrets.sh` - **keep this** (still useful)
- ✅ `bash/scripts/age-key-setup.sh` - **keep this** (still useful)

---

## 🎓 Next Steps

1. **Test the new setup:**
   ```bash
   cd ~/linuxdevenv/home-manager
   home-manager switch --flake .
   ```

2. **Customize to your needs:**
   - Add your actual username to `flake.nix` (line 19)
   - Add Git secrets to `home.nix` (from private.yml)
   - Adjust packages/configs as needed

3. **Learn more:**
   - [Home Manager Manual](https://nix-community.github.io/home-manager/)
   - [Nix Flakes](https://nixos.wiki/wiki/Flakes)
   - Search [Home Manager Options](https://mipmip.github.io/home-manager-option-search/)

---

## ❓ FAQ

**Q: Do I need to delete the old bash scripts?**
A: No! Keep them around during transition. You can phase them out gradually.

**Q: What if a package isn't in nixpkgs?**
A: Very rare, but you can use `home.activation` scripts for edge cases.

**Q: Can I use this on macOS?**
A: Yes! Change `system = "x86_64-darwin"` in flake.nix (or use `aarch64-darwin` for Apple Silicon).

**Q: How do I update packages?**
A: `nix flake update` updates the flake.lock, then `home-manager switch` applies updates.

**Q: Can I split home.nix into modules?**
A: Yes! Create separate files like `modules/fish.nix` and import them.

---

## 🎉 Benefits Summary

✅ **Single command** to apply all changes
✅ **Idempotent** - safe to run anytime
✅ **Rollback** built-in
✅ **Reproducible** across machines/distros
✅ **Version controlled** config (see exactly what changed)
✅ **No manual state management** - HM handles it
✅ **Future-proof** for distro-hopping
