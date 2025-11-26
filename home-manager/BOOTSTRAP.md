# Bootstrap Workflow: Master + Machine Keys

This document explains how to use the master bootstrap key + machine-specific keys approach for managing secrets across multiple machines.

## 🔑 Key Architecture

### Two Types of Keys:

1. **Master Bootstrap Key** (one per person)
   - Stored securely in 1Password
   - Used ONLY during new machine setup
   - Never stored permanently on any machine
   - Can decrypt secrets from anywhere

2. **Machine-Specific Keys** (one per machine)
   - Generated automatically during setup
   - Stored at `~/.config/sops/age/keys.txt`
   - Used for daily operations
   - Different on each machine

### How private.yml is Encrypted:

Your `private.yml` is encrypted for **BOTH**:
- Your master bootstrap key
- All your machine-specific keys

This means:
- ✅ Master key can always decrypt (for bootstrapping)
- ✅ Each machine can decrypt with its own key (for daily use)
- ✅ You can revoke a machine by removing its key and rekeying

---

## 🚀 Initial Setup (One Time)

### Step 1: Generate Master Bootstrap Key

Run this ONCE (probably on your first/main machine):

```bash
cd ~/linuxdevenv/home-manager
./bootstrap-setup.sh
```

This will:
1. Generate a master Age key
2. Display the private key
3. Offer to add the public key to `.sops.yaml`

**IMPORTANT:** Copy the private key (starts with `AGE-SECRET-KEY-`) and save it in 1Password with the title "SOPS Bootstrap Key"

### Step 2: Rekey Your Secrets

If you already have secrets encrypted with your machine keys, rekey them to include the bootstrap key:

```bash
cd ~/linuxdevenv/bash
./manage-secrets.sh reencrypt
```

Now `private.yml` is encrypted for both your bootstrap key and existing machine keys.

### Step 3: Commit and Push

```bash
cd ~/linuxdevenv
git add bash/config/.sops.yaml bash/config/private.yml
git commit -m "Add master bootstrap key to SOPS config"
git push
```

---

## 💻 Setting Up a New Machine

### The Easy Way (Automated):

```bash
# Clone your repo
git clone <your-repo-url> ~/linuxdevenv
cd ~/linuxdevenv/home-manager

# Run install.sh - it will guide you through the process
./install.sh
```

When prompted, paste your master bootstrap key from 1Password.

### What Happens Automatically:

1. ✅ Verifies bootstrap key can decrypt secrets
2. ✅ Generates a new machine-specific Age key
3. ✅ Adds machine key to `.sops.yaml`
4. ✅ Re-encrypts `private.yml` with updated key list
5. ✅ Commits and pushes changes to git
6. ✅ Cleans up bootstrap key (not stored on disk)

After this, the machine will use its own key for daily operations.

---

## 🔄 Daily Workflow (After Setup)

Once your machine is set up, you don't need the bootstrap key anymore:

```bash
# Edit secrets (uses your machine key)
cd ~/linuxdevenv/bash
./manage-secrets.sh edit config/private.yml

# Apply changes
cd ../home-manager
home-manager switch --flake .
```

Your machine key at `~/.config/sops/age/keys.txt` is used automatically.

---

## 🔐 Security Model

### What You Have:

| Key Type | Location | Used For |
|----------|----------|----------|
| Master bootstrap key | 1Password only | New machine setup |
| Machine key (laptop) | `~/.config/sops/age/keys.txt` | Daily operations |
| Machine key (desktop) | `~/.config/sops/age/keys.txt` | Daily operations |
| Machine key (server) | `~/.config/sops/age/keys.txt` | Daily operations |

### Why This Works:

- **Easy new machine setup:** Just paste bootstrap key once
- **Daily operations don't need bootstrap key:** Each machine uses its own key
- **Can revoke machines:** Remove key from `.sops.yaml`, rekey, push
- **Bootstrap key compromise:** Rotate it, update `.sops.yaml`, rekey
- **Machine compromise:** Remove that machine's key, rekey

---

## 🚨 Emergency Procedures

### Lost Bootstrap Key

If you lose your bootstrap key but still have access to any existing machine:

1. Generate a new bootstrap key:
   ```bash
   ./bootstrap-setup.sh
   ```

2. Add it to `.sops.yaml`:
   ```bash
   cd ../bash
   ./manage-secrets.sh reencrypt
   ```

3. Store the new key in 1Password

Your existing machines continue working with their machine keys.

### Machine Compromised

If a machine is compromised:

1. Remove its public key from `.sops.yaml`
2. Rekey secrets:
   ```bash
   cd bash
   ./manage-secrets.sh reencrypt
   git add config/.sops.yaml config/private.yml
   git commit -m "Revoke key for compromised machine"
   git push
   ```

3. Pull on other machines:
   ```bash
   git pull
   ```

The compromised machine can no longer decrypt new secrets (but it already had access to the old values, so rotate any sensitive data).

### Rotate All Keys

If you want to rotate everything:

1. Generate new bootstrap key
2. On each machine, generate new machine key
3. Update `.sops.yaml` with all new public keys
4. Rekey private.yml
5. Rotate any secrets that old keys had access to

---

## 📋 Troubleshooting

### "Bootstrap key cannot decrypt private.yml"

**Cause:** The bootstrap key's public key isn't in `.sops.yaml`

**Fix:**
1. Run `./bootstrap-setup.sh` to see your bootstrap public key
2. Check if it's in `../bash/config/.sops.yaml`
3. If not, add it and run `cd ../bash && ./manage-secrets.sh reencrypt`

### "Machine key already in .sops.yaml"

**Cause:** This machine was already set up

**Fix:** Nothing! This is normal. The script detected an existing setup.

### "Failed to rekey private.yml"

**Cause:** Bootstrap key might be wrong, or SOPS config issue

**Fix:**
1. Script automatically restores backup `.sops.yaml.bak`
2. Verify bootstrap key in 1Password
3. Try again

### Git push fails

**Cause:** Network issue or need to pull first

**Fix:**
```bash
cd bash/config
git pull --rebase
git push
```

---

## 📚 Key Concepts

### Why Not Just One Key?

**With single key shared across machines:**
- ❌ If key compromised, all machines affected
- ❌ Can't revoke individual machines
- ❌ Key is on multiple disks (higher exposure)

**With master + machine keys:**
- ✅ Each machine has unique key
- ✅ Revoke individual machines easily
- ✅ Master key only exposed during setup
- ✅ Daily operations use machine-specific keys

### Why Commit Encrypted Keys to Git?

The `.sops.yaml` file only contains **public keys**, which are safe to commit. The `private.yml` is encrypted, so it's also safe to commit. Only someone with a private key (master or machine) can decrypt it.

### Can I Add More Bootstrap Keys?

Yes! If you work with a team, each person can have their own bootstrap key. All bootstrap keys can decrypt secrets. Just add their public keys to `.sops.yaml`.

---

## 🎓 Advanced Usage

### Multiple Bootstrap Keys (Team Setup)

```yaml
# .sops.yaml
creation_rules:
  - path_regex: .*
    age: >-
      age1abc...  # Alice's bootstrap key
      age1def...  # Bob's bootstrap key
      age1ghi...  # Alice's laptop
      age1jkl...  # Bob's desktop
```

Now both Alice and Bob can bootstrap new machines with their own keys.

### Per-Environment Keys

You can have different encryption for different files:

```yaml
# .sops.yaml
creation_rules:
  - path_regex: production.yml
    age: >-
      age1abc...  # Only production keys
  - path_regex: development.yml
    age: >-
      age1xyz...  # Only dev keys
```

### Backup Strategy

1. **Bootstrap key:** In 1Password (primary) and secure offline backup
2. **Machine keys:** Backed up with machine (or regenerate as needed)
3. **Encrypted secrets:** In git (safe because encrypted)

---

## ✅ Quick Reference

| Task | Command |
|------|---------|
| Generate bootstrap key | `./bootstrap-setup.sh` |
| Set up new machine | `./install.sh` (prompts for bootstrap key) |
| Edit secrets | `cd ../bash && ./manage-secrets.sh edit config/private.yml` |
| View secrets | `cd ../bash && ./manage-secrets.sh view config/private.yml` |
| Rekey after .sops.yaml change | `cd ../bash && ./manage-secrets.sh reencrypt` |
| Revoke a machine | Remove key from `.sops.yaml`, run reencrypt, push |
