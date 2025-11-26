# Secrets Integration with SOPS

Home Manager is now configured to automatically read your Git credentials from the encrypted `private.yml` file using SOPS and Age encryption.

## 🔑 Key Management Approach

This setup uses **Master Bootstrap Key + Machine-Specific Keys**:

- **Master key:** Stored in 1Password, used only for new machine setup
- **Machine keys:** Generated per machine, used for daily operations
- **Secrets encrypted for both:** Any key can decrypt

See **[BOOTSTRAP.md](./BOOTSTRAP.md)** for full details on this architecture.

## How It Works

1. **sops-nix** integration reads your encrypted `bash/config/private.yml`
2. Decrypts it using your Age key at `~/.config/sops/age/keys.txt`
3. Extracts `git_user/name` and `git_user/email`
4. Automatically configures Git with these values

## Quick Setup

### On a New Machine:

```bash
cd ~/linuxdevenv/home-manager
./install.sh
# When prompted, paste your bootstrap key from 1Password
```

That's it! The script will:
- Generate a machine-specific key
- Update `.sops.yaml`
- Rekey `private.yml`
- Commit and push changes

### On Existing Machines:

If your machine already has an Age key, `install.sh` will use it automatically. No bootstrap key needed.

## Prerequisites

Before running `home-manager switch`, you need:

### 1. Age Key Exists
```bash
# Check if you have an Age key
ls ~/.config/sops/age/keys.txt

# If not, generate one:
cd ~/linuxdevenv/bash
./age-key-setup.sh generate
```

### 2. Private Config Has Your Git Info

Edit your encrypted private config:
```bash
cd ~/linuxdevenv/bash
./manage-secrets.sh edit config/private.yml
```

Set your Git credentials:
```yaml
git_user:
    name: "Your Full Name"
    email: "your.email@example.com"
    signing_key: ""  # Optional: GPG key ID for signing commits
```

Save and exit. The file will be automatically re-encrypted.

### 3. Verify the Values
```bash
./manage-secrets.sh view config/private.yml
```

You should see your name and email populated.

## What Gets Configured

Once you run `home-manager switch`, these Git settings will be automatically applied:

```bash
git config --global user.name "Your Full Name"
git config --global user.email "your.email@example.com"
```

## First Time Setup

If this is a fresh machine:

```bash
# 1. Clone your repo
git clone <your-repo> ~/linuxdevenv

# 2. Set up Age key (import existing or generate new)
cd ~/linuxdevenv/bash
./age-key-setup.sh import <your-age-key-string>
# OR
./age-key-setup.sh generate

# 3. If you generated a new key, add it to .sops.yaml
#    (See age-key-setup.sh output for instructions)

# 4. Edit private.yml to add your Git info
./manage-secrets.sh edit config/private.yml

# 5. Now run Home Manager
cd ../home-manager
./install.sh
```

## Troubleshooting

### Error: "age key not found"
```bash
# Your Age key doesn't exist yet
cd ~/linuxdevenv/bash
./age-key-setup.sh generate
```

### Error: "could not decrypt"
```bash
# Your Age key doesn't match the one used to encrypt private.yml
# Either:
# 1. Import the correct key: ./age-key-setup.sh import <key>
# 2. Re-encrypt with your current key: ./manage-secrets.sh rekey
```

### Git config is empty after home-manager switch
```bash
# Check if your private.yml has values:
./bash/manage-secrets.sh view bash/config/private.yml

# If git_user.name and git_user.email are empty (""), edit them:
./bash/manage-secrets.sh edit bash/config/private.yml
```

## Advanced: GPG Signing

If you want to sign your commits with GPG:

1. Generate or import a GPG key
2. Get your key ID: `gpg --list-secret-keys --keyid-format=long`
3. Add it to private.yml:
   ```yaml
   git_user:
       signing_key: "YOUR_GPG_KEY_ID"
   ```
4. Uncomment the signing block in `home.nix` (lines 186-189)
5. Run `home-manager switch --flake .`

## Benefits

✅ **Secrets never in plaintext** - private.yml is always encrypted in git
✅ **Automatic configuration** - No manual `git config` commands needed
✅ **Multi-machine sync** - Same encrypted file works on all machines (with your Age key)
✅ **Version controlled** - Changes to secrets are tracked (but encrypted)

## Your Existing Workflow Still Works

You can still use your bash scripts:
- `./manage-secrets.sh edit` - Edit secrets
- `./manage-secrets.sh view` - View secrets
- `./manage-secrets.sh rekey` - Add new machines

Home Manager just reads from the same file!
