# Linux Development Environment Setup

This project provides automated scripts to set up a complete Linux development environment. It includes two implementation approaches:

1. **Bash Script**: A standalone shell script for direct execution
2. **Ansible Playbook**: A more maintainable and modular approach using Ansible

Both implementations support the same features and can be configured using the same YAML configuration files.

## Features

- Nix package manager installation and package setup
- Homebrew installation and package setup
- Git configuration with user info and signing keys
- SSH key generation and configuration
- GitHub SSH key registration
- Fish shell configuration with plugins
- Neovim setup with NvChad
- TMUX configuration with plugin manager
- Nerd Font installation
- Chezmoi dotfiles integration
- Secure handling of sensitive information

## Configuration Files

The setup uses two separate configuration files:

1. **Public Configuration** (`public-config.yml`): Contains non-sensitive settings that can be committed to a public repository.
2. **Private Configuration** (`private-config.yml`): Contains sensitive information (SSH keys, tokens) that should be encrypted before being committed.

## Quick Start

### Option 1: Using the Bash Script

1. Copy and edit the configuration files:
   ```bash
   cp public-config.yml.example public-config.yml
   cp private-config.yml.example private-config.yml
   ```

2. Edit the configuration files to match your preferences.

3. For security, encrypt the private configuration (optional but recommended):
   ```bash
   # Using SOPS
   sops -e -i private-config.yml
   ```

4. Run the setup script:
   ```bash
   # With unencrypted private config
   ./load-config.sh --public public-config.yml --private private-config.yml
   ./setup-dev-env.sh
   
   # With SOPS-encrypted private config
   ./load-config.sh --public public-config.yml --private private-config.enc.yml --sops
   ./setup-dev-env.sh
   ```

### Option 2: Using Ansible

1. Copy and edit the configuration files (same as above).

2. Install Ansible:
   ```bash
   sudo apt update
   sudo apt install -y ansible
   ```

3. For security, encrypt the private configuration with Ansible Vault:
   ```bash
   ansible-vault encrypt private-config.yml
   ```

4. Run the playbook:
   ```bash
   # With unencrypted private config
   ansible-playbook -i inventory.ini dev-setup.yml -e "@public-config.yml" -e "@private-config.yml"
   
   # With Ansible Vault encrypted private config
   ansible-playbook -i inventory.ini dev-setup.yml -e "@public-config.yml" -e "@private-config.yml" --ask-vault-pass
   ```

## Advanced Ansible Usage

### Multiple Ways to Include Configuration Files

1. **Command line variables**:
   ```bash
   ansible-playbook -i inventory.ini dev-setup.yml -e "@public-config.yml" -e "@private-config.yml"
   ```

2. **Using vars_files in the playbook**:
   ```yaml
   # In dev-setup.yml
   vars_files:
     - public-config.yml
     - private-config.yml
   ```

3. **Using group variables**:
   ```
   my-ansible-setup/
   ├── group_vars/
   │   ├── all/
   │   │   ├── public.yml  # Copy contents of public-config.yml here
   │   │   └── private.yml # Copy contents of private-config.yml here (can be vault encrypted)
   ├── inventory.ini
   └── dev-setup.yml
   ```

### Running Specific Tasks with Tags

```bash
# Just set up Git and SSH
ansible-playbook -i inventory.ini dev-setup.yml --tags "git,ssh"

# Just install Nix packages
ansible-playbook -i inventory.ini dev-setup.yml --tags "nix"

# Just set up dotfiles
ansible-playbook -i inventory.ini dev-setup.yml --tags "chezmoi,dotfiles"
```

### Overriding Specific Variables

```bash
ansible-playbook -i inventory.ini dev-setup.yml \
  -e "@public-config.yml" \
  -e "@private-config.yml" \
  -e "nerd_font=JetBrainsMono dotfiles_branch=develop"
```

## Security Considerations

### SOPS Encryption for Bash Script

The `load-config.sh` script supports SOPS-encrypted private configuration files:

```bash
# Encrypt private config
sops -e private-config.yml > private-config.enc.yml

# Use encrypted config
./load-config.sh --public public-config.yml --private private-config.enc.yml --sops
```

### Ansible Vault for Ansible Playbook

Ansible Vault can be used to encrypt sensitive information. The recommended approach is to encrypt the entire private configuration file:

```bash
# Encrypt the entire file
ansible-vault encrypt private-config.yml

# Edit the encrypted file later
ansible-vault edit private-config.yml

# View contents without editing
ansible-vault view private-config.yml
```

When running the playbook with an encrypted file, provide the vault password:

```bash
ansible-playbook -i inventory.ini dev-setup.yml -e "@public-config.yml" -e "@private-config.yml" --ask-vault-pass
```

#### Using a Vault Password File

Instead of typing the password each time, you can store it in a file:

```bash
# Create a vault password file
echo "your_secure_password" > ~/.vault_pass.txt
chmod 600 ~/.vault_pass.txt

# Use the password file
ansible-playbook -i inventory.ini dev-setup.yml -e "@public-config.yml" -e "@private-config.yml" --vault-password-file=~/.vault_pass.txt
```

You can also configure this in your `ansible.cfg` file:

```ini
[defaults]
vault_password_file = ~/.vault_pass.txt
```

Then run the playbook without specifying the vault password file:

```bash
ansible-playbook -i inventory.ini dev-setup.yml -e "@public-config.yml" -e "@private-config.yml"
```

## Files in this Repository

- **Configuration**:
  - `public-config.yml`: Non-sensitive configuration options
  - `private-config.yml`: Sensitive configuration options

- **Bash Script Approach**:
  - `setup-dev-env.sh`: Main bash script for environment setup
  - `load-config.sh`: Helper script to load YAML configuration

- **Ansible Approach**:
  - `dev-setup.yml`: Ansible playbook for environment setup
  - `inventory.ini`: Ansible inventory file

## Requirements

- A Debian/Ubuntu-based Linux distribution (some features may work on other distributions)
- Sudo access
- Internet connection
- `yq` (required for the bash script to parse YAML files)
- `sops` (optional, for encrypting private configuration)
- `ansible` (required for the Ansible approach)

## Notes

- The bash script will prompt for sudo access when needed
- Some features are Ubuntu/Debian specific and may not work on other distributions
- You may need to log out and back in for shell changes to take effect
- Ensure that SSH keys and GitHub API tokens have the correct permissions
- The GitHub SSH integration requires an API token with appropriate scopes (typically `admin:public_key`)