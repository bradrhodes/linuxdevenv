# Home Manager Configuration

This directory contains your declarative Home Manager configuration using Nix Flakes.

**What is this?** A single configuration that installs and manages all your development tools, shell configs, and dotfiles across any Linux machine. Make a change once, sync everywhere.

## TL;DR - Quick Workflow

**New machine setup:**
```bash
# Clone repo → run installer → set fish as default
git clone git@github.com:<you>/linuxdevenv.git ~/linuxdevenv
cd ~/linuxdevenv/home-manager && ./install.sh
sudo chsh -s $(which fish) $USER
```

**Make changes on current machine:**
```bash
# Edit config → apply → commit → push
vim home.nix
home-manager switch --flake .
git add home.nix && git commit -m "Added X" && git push
```

**Sync changes to other machines:**
```bash
# Pull → apply
cd ~/linuxdevenv && git pull
cd home-manager && home-manager switch --flake .
```

---

## 🚀 Setup on a New Machine

### Step 1: Get SSH Access to Clone Repo

Since this repo is private, generate an SSH key first:

```bash
# Generate SSH key
ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519 -N ""

# Display public key
cat ~/.ssh/id_ed25519.pub

# Add to GitHub: https://github.com/settings/keys
# Test connection
ssh -T git@github.com
```

### Step 2: Clone and Install

```bash
# Clone the repo
git clone git@github.com:<your-username>/linuxdevenv.git ~/linuxdevenv
cd ~/linuxdevenv/home-manager

# Run the installer
./install.sh
```

**First time ever?** The installer will prompt you to paste your **master bootstrap key** from 1Password.

**What it does:**
- ✅ Installs Nix (if needed)
- ✅ Generates a machine-specific encryption key
- ✅ Updates `.sops.yaml` with the new key
- ✅ Commits and pushes the changes
- ✅ Installs all packages (Fish, Tmux, Neovim, etc.)
- ✅ Configures everything declaratively

### Step 3: Set Fish as Default Shell

```bash
sudo chsh -s $(which fish) $USER
# Log out and back in
```

**Done!** Your machine now has the exact same environment as all your other machines.

---

## 🔄 Making Changes and Syncing Across Machines

### Workflow: Change on One Machine → Sync to Others

#### 1. Make Changes on Current Machine

**Add a package:**
```bash
cd ~/linuxdevenv/home-manager
# Edit home.nix
vim home.nix  # or: nvim home.nix
```

Add to the `home.packages` list:
```nix
home.packages = with pkgs; [
  ripgrep
  bat
  htop
  jq        # ← Add your new package here
];
```

**Change a config (e.g., Fish alias):**
```nix
programs.fish = {
  shellAliases = {
    ll = "eza -la";
    cat = "bat";
    myalias = "echo hello";  # ← Add your alias here
  };
};
```

#### 2. Apply Changes Locally

```bash
# Apply the configuration
home-manager switch --flake .

# Verify it works
jq --version  # If you added jq
myalias       # If you added an alias
```

#### 3. Commit and Push to Git

```bash
cd ~/linuxdevenv
git add home-manager/home.nix
git commit -m "Add jq package and custom alias"
git push
```

#### 4. Sync to Other Machines

On **any other machine**, simply:

```bash
# Pull the latest changes
cd ~/linuxdevenv
git pull

# Apply the updated configuration
cd home-manager
home-manager switch --flake .
```

**That's it!** The other machine now has the same packages and configs.

---

## 📝 Common Operations

### Add/Remove Packages

**Add a package:**
1. Edit `home.nix` → Add to `home.packages`
2. Run `home-manager switch --flake .`
3. Commit and push: `git add home.nix && git commit -m "Add X" && git push`

**Remove a package:**
1. Edit `home.nix` → Remove from `home.packages`
2. Run `home-manager switch --flake .`
3. Commit and push

### Change Shell Configuration

**Fish aliases/config:**
- Edit the `programs.fish` section in `home.nix`
- Apply: `home-manager switch --flake .`
- Your `~/.config/fish/config.fish` will be regenerated

**Tmux config:**
- Edit the `programs.tmux` section in `home.nix`
- Apply: `home-manager switch --flake .`
- Your `~/.config/tmux/tmux.conf` will be regenerated

### Update All Packages

```bash
# Update flake inputs (gets latest package versions)
nix flake update

# Apply updates
home-manager switch --flake .

# Commit the updated lock file
git add flake.lock
git commit -m "Update package versions"
git push
```

### Edit Secrets (Git Credentials, etc.)

```bash
cd ~/linuxdevenv/bash
./manage-secrets.sh edit config/private.yml

# Make your changes (git_user.name, git_user.email, etc.)
# Save and exit - file is automatically re-encrypted

# Apply changes (re-generates git config)
cd ../home-manager
home-manager switch --flake .

# Commit and push (private.yml is encrypted, safe to commit)
cd ..
git add bash/config/private.yml
git commit -m "Update git credentials"
git push
```

### View What Would Change (Dry Run)

```bash
home-manager switch --flake . --dry-run
```

### Rollback to Previous Configuration

```bash
# List previous generations
home-manager generations

# Rollback to previous
home-manager switch --rollback
```

---

## 🔑 First-Time Setup: Bootstrap Key

**Only needed the very first time you set this up:**

```bash
cd ~/linuxdevenv/home-manager
./bootstrap-setup.sh
# Save the private key to 1Password with title "SOPS Bootstrap Key"
```

This creates a master key that can decrypt secrets on any new machine. You'll paste it once when setting up each new machine, then never need it again on that machine (each machine gets its own key).

**See [BOOTSTRAP.md](./BOOTSTRAP.md) for full details on key management.**

---

## 🔐 Secrets Integration

Your Git credentials are **automatically loaded** from the encrypted `../bash/config/private.yml`:

```nix
# In home.nix - Git credentials come from SOPS-encrypted file
userName = builtins.readFile config.sops.secrets."git_user/name".path;
userEmail = builtins.readFile config.sops.secrets."git_user/email".path;
```

The file is encrypted with SOPS/Age, so it's safe to commit to git. Only machines with the correct Age key can decrypt it.

**See [SECRETS.md](./SECRETS.md) for full details.**

---

## 📁 What's Installed

After running `install.sh`, you'll have:

**Shells & Tools:**
- Fish shell with plugins (z, fzf, autopair, bass)
- Tmux with sensible defaults and session management
- Neovim with LazyVim pre-configured
- Starship prompt

**CLI Tools:**
- `ripgrep` (rg) - Fast grep replacement
- `bat` - Cat with syntax highlighting
- `eza` - Modern ls replacement
- `fzf` - Fuzzy finder
- `htop` - Process viewer
- `lazygit` - Git TUI
- `jq` - JSON processor (via yq-go)
- `uv` - Python package manager
- `posting` - HTTP client TUI
- `ncdu`, `duckdb`, `mc`, and more

**Fonts:**
- EnvyCodeR Nerd Font (pre-installed)

**Development:**
- GCC, Make, Binutils
- Git with aliases
- SSH keys (auto-generated)

**Secrets Management:**
- SOPS, Age, yq-go (for encrypted configs)

---

## 📚 Additional Documentation

- **[BOOTSTRAP.md](./BOOTSTRAP.md)** - Master + machine key workflow (how secrets work)
- **[SECRETS.md](./SECRETS.md)** - SOPS integration details
- **[MIGRATION.md](./MIGRATION.md)** - Full migration guide from bash scripts
- **[SUMMARY.md](./SUMMARY.md)** - High-level overview of the setup
- **[COMPARISON.md](./COMPARISON.md)** - Old bash scripts vs new Home Manager

---

## 🗂️ File Structure

```
home-manager/
├── flake.nix           # Nix flake definition (includes sops-nix)
├── home.nix            # Main configuration (packages, programs, dotfiles)
├── flake.lock          # Locked dependency versions (commit this!)
├── install.sh          # First-time installation script
├── bootstrap-setup.sh  # Generate master bootstrap key (run once)
└── *.md                # Documentation files
```

---

## 🔧 Troubleshooting

### "error: experimental feature 'nix-command' is required"
Enable flakes:
```bash
mkdir -p ~/.config/nix
echo "experimental-features = nix-command flakes" >> ~/.config/nix/nix.conf
```

### "collision between X and Y"
Two packages are trying to install the same file. Check your `home.packages` for duplicate or conflicting packages.

### Fish shell not available after switch
Fish is installed but you need to log out and back in. Or run:
```bash
exec fish
```

### Changes not taking effect
1. Make sure you ran `home-manager switch --flake .`
2. For shell changes, restart your terminal or run `exec fish`
3. For secrets, verify they're decrypted: `cd ../bash && ./manage-secrets.sh view config/private.yml`

### Can't decrypt secrets on new machine
1. Make sure you pasted the correct bootstrap key during `install.sh`
2. Check if your machine key was added to `.sops.yaml`: `cat ../bash/config/.sops.yaml`
3. Verify Age key exists: `ls ~/.config/sops/age/keys.txt`

---

## 🌐 Resources

- [Home Manager Manual](https://nix-community.github.io/home-manager/)
- [Home Manager Options Search](https://mipmip.github.io/home-manager-option-search/)
- [Nix Package Search](https://search.nixos.org/packages)
- [Nix Flakes Guide](https://nixos.wiki/wiki/Flakes)

---

## 🚀 Advanced: Modular Configuration

As your config grows, you can split `home.nix` into modules:

```
home-manager/
├── flake.nix
├── home.nix          # Import modules here
└── modules/
    ├── fish.nix
    ├── tmux.nix
    ├── git.nix
    └── neovim.nix
```

Then in `home.nix`:
```nix
imports = [
  ./modules/fish.nix
  ./modules/tmux.nix
  ./modules/git.nix
  ./modules/neovim.nix
];
```
