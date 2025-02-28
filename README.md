# Linux Development Environment Setup

This project provides automated scripts to set up a complete Linux development environment. It includes two implementation approaches:

1. **Bash Script**: A standalone shell script for direct execution
2. **Ansible Playbook**: A more maintainable and modular approach using Ansible

Both implementations support the same features and can be configured using YAML configuration files.

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

1. **Public Configuration**: Contains non-sensitive settings that can be committed to a public repository.
2. **Private Configuration**: Contains sensitive information (SSH keys, tokens) that should be encrypted before being committed.

All configuration options must be defined in these files - the scripts do not have default values and will fail if configuration files are missing.

## Option 1: Using the Bash Script

### Setup

1. Copy the example configuration files:
   ```bash
   cp public-config.yml.example public-config.yml
   cp private-config.yml.example private-config.yml
   ```

2. Edit the configuration files to match your preferences:
   ```bash
   # Edit public configuration
   nano public-config.yml

   # Edit private configuration
   nano private-config.yml
   ```

3. (Optional) Encrypt the private configuration file with SOPS:
   ```bash
   # Install SOPS if needed
   brew install sops

   # Encrypt the private configuration
   sops -e -i private-config.yml
   ```

4. Run the setup script:
   ```bash
   # With unencrypted private config
   ./load-config.sh --public public-config.yml --private private-config.yml
   ./setup-dev-env.sh
   
   # With SOPS-encrypted private config
   ./load-config.sh --public public-config.yml --private private-config.yml --sops
   ./setup-dev-env.sh
   ```

### SOPS Encryption for Bash Script

The `load-config.sh` script supports SOPS-encrypted private configuration files:

```bash
# Encrypt private config
sops -e private-config.yml > private-config.enc.yml

# Use encrypted config
./load-config.sh --public public-config.yml --private private-config.enc.yml --sops
```

## Option 2: Using Ansible

### Setup

1. Create the required directory structure:
   ```bash
   mkdir -p group_vars/all
   ```

2. Copy the example configuration files:
   ```bash
   cp public.yml.example group_vars/all/public.yml
   cp private.yml.example group_vars/all/private.yml
   ```

3. Edit the configuration files to match your preferences:
   ```bash
   # Edit public configuration
   nano group_vars/all/public.yml

   # Edit private configuration
   nano group_vars/all/private.yml
   ```

4. Install Ansible if you haven't already:
   ```bash
   sudo apt update
   sudo apt install -y ansible
   ```

5. (Optional) Encrypt the private configuration file:
   ```bash
   ansible-vault encrypt group_vars/all/private.yml
   ```

6. Run the playbook:
   ```bash
   # If your private configuration is not encrypted:
   ansible-playbook -i inventory.ini dev-setup.yml --ask-become-pass

   # If your private configuration is encrypted:
   ansible-playbook -i inventory.ini dev-setup.yml --ask-vault-pass --ask-become-pass
   ```

### Advanced Ansible Usage

#### Using a Different Configuration Location

You can also use the `-e` flag to specify configuration files in different locations:

```bash
ansible-playbook -i inventory.ini dev-setup.yml -e "@path/to/public.yml" -e "@path/to/private.yml" --ask-become-pass
```

#### Dry Run (Check Mode)

To perform a dry run without making changes:

```bash
ansible-playbook -i inventory.ini dev-setup.yml --check --ask-become-pass
```

#### Running Specific Tasks with Tags

```bash
# Just set up Git and SSH
ansible-playbook -i inventory.ini dev-setup.yml --tags "git,ssh" --ask-become-pass

# Just install Homebrew packages
ansible-playbook -i inventory.ini dev-setup.yml --tags "homebrew" --ask-become-pass

# Just set up dotfiles
ansible-playbook -i inventory.ini dev-setup.yml --tags "chezmoi,dotfiles" --ask-become-pass
```

### Ansible Vault for Encrypting Private Information

Ansible Vault can be used to encrypt sensitive information. The recommended approach is to encrypt the entire private configuration file:

```bash
# Encrypt the entire file
ansible-vault encrypt group_vars/all/private.yml

# Edit the encrypted file later
ansible-vault edit group_vars/all/private.yml

# View contents without editing
ansible-vault view group_vars/all/private.yml
```

When running the playbook with an encrypted file, provide the vault password:

```bash
ansible-playbook -i inventory.ini dev-setup.yml --ask-vault-pass --ask-become-pass
```

#### Using a Vault Password File

Instead of typing the password each time, you can store it in a file:

```bash
# Create a vault password file
echo "your_secure_password" > ~/.vault_pass.txt
chmod 600 ~/.vault_pass.txt

# Use the password file
ansible-playbook -i inventory.ini dev-setup.yml --vault-password-file=~/.vault_pass.txt --ask-become-pass
```

You can also configure this in your `ansible.cfg` file:

```ini
[defaults]
vault_password_file = ~/.vault_pass.txt
```

Then run the playbook without specifying the vault password file:

```bash
ansible-playbook -i inventory.ini dev-setup.yml --ask-become-pass
```

## Files in this Repository

- **Configuration Templates**:
  - `public-config.yml.example` / `public.yml.example`: Templates for non-sensitive configuration options
  - `private-config.yml.example` / `private.yml.example`: Templates for sensitive configuration options

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
- For Bash script: `yq` (required to parse YAML files) and `sops` (optional, for encrypting private configuration)
- For Ansible: `ansible` installed on your system

## Notes

- Both scripts will fail if configuration files are missing
- Some features are Ubuntu/Debian specific and may not work on other distributions
- You may need to log out and back in for shell changes to take effect
- Ensure that SSH keys and GitHub API tokens have the correct permissions
- The GitHub SSH integration requires an API token with appropriate scopes (typically `admin:public_key`)