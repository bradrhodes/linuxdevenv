# Linux Development Environment Setup

A complete solution for bootstrapping and configuring a Linux development environment with secure configuration management.

## Overview

This toolkit provides scripts to set up a comprehensive development environment on Linux systems. It includes:

- Bootstrap process to install essential prerequisites
- Secure management of sensitive configuration using SOPS with Age encryption
- Nix package manager integration
- Fish shell configuration
- Neovim and TMUX setup
- SSH and Git configuration
- Dotfiles management via Chezmoi

## Directory Structure
```
/
├── bootstrap.sh         # Installs prerequisites 
├── age-key-setup.sh     # Sets up Age encryption
├── manage-secrets.sh    # Manages encrypted configuration
├── dev-env-setup.sh     # Main setup script (handles decryption)
├── README.md
├── config/
│   ├── public.yml       # Public configuration
│   ├── private.yml      # Encrypted private configuration
│   ├── private.example.yml  # Template for private configuration
│   └── .sops.yaml       # SOPS encryption configuration
└── scripts/
    ├── logging.sh       # Centralized logging module
    └── load-config.sh   # Configuration loading script
```

## Quick Start

### First-time Setup (Creating New Configuration)

```bash
# 1. Clone this repository
git clone https://github.com/yourusername/dev-env-setup.git
cd dev-env-setup

# 2. Run the bootstrap script to install prerequisites (including Age)
chmod +x bootstrap.sh
./bootstrap.sh

# 3. Set up Age encryption key
chmod +x age-key-setup.sh
./age-key-setup.sh

# 4. Initialize your private configuration
chmod +x manage-secrets.sh
./manage-secrets.sh init

# 5. Run the setup
chmod +x setup.sh
./setup.sh
```

### Additional Machine Setup (Using Existing Configuration)

If you already have an encrypted `private.yml` in your repository:

```bash
# 1. Clone this repository
git clone https://github.com/yourusername/dev-env-setup.git
cd dev-env-setup

# 2. Run the bootstrap script to install prerequisites (including Age)
chmod +x bootstrap.sh
./bootstrap.sh

# 3. Import your Age key from original machine
chmod +x age-key-setup.sh
./age-key-setup.sh import /path/to/exported-key.txt

# 4. Run the setup directly
chmod +x setup.sh
./setup.sh
```

## Setup Process

### 1. Bootstrap

The bootstrap script prepares your system with the essential tools needed before running the main setup:

```bash
./bootstrap.sh
```

This script:
- Checks for required tools (git, curl, unzip, sops, yq, age)
- Installs any missing prerequisites (including Age for encryption)
- Works across various Linux distributions
- Uses package managers when available, with fallbacks to manual installation

> **Note:** Age is not typically installed by default on Linux distributions, but the bootstrap script will automatically install it for you. This is required for the encrypted configuration to work.

### 2. Age Key Setup

Before using SOPS, you need to set up an Age encryption key:

```bash
./age-key-setup.sh
```

This will:
1. Generate a new Age key pair in `~/.age/keys.txt`
2. Configure SOPS to use your Age public key
3. Set up the necessary environment variables

### 3. Secret Management

Before running the main setup, you need to create or import your private configuration settings.

#### 3.1 First-Time Setup (New Key)

If you're setting up for the first time or want to create a new Age key:

```bash
# Create and encrypt your private configuration
./manage-secrets.sh init
```

This will:
1. Copy the `private.example.yml` template
2. Open it in your default editor (or vim)
3. Encrypt it with SOPS and Age after saving

#### 3.2 Using an Existing Key

If you already have an Age key from another machine, you need to transfer it to your new machine. Here are a few approaches:

**Option 1: Export/Import (if both machines have networking)**

On your original machine:
```bash
./age-key-setup.sh export  # Creates age-key-export.txt
```

Transfer this file to your new machine, then:
```bash
./age-key-setup.sh import age-key-export.txt
```

**Option 2: Manual Creation (simplest for fresh systems)**

The Age keys file has a specific format. On your original machine:
```bash
cat ~/.age/keys.txt  # View and copy the content
```

On your new machine:
```bash
# Create a temporary keys file in the current directory
vim age-key-export.txt  # Paste the exact content, preserving all lines
chmod 600 age-key-export.txt

# Import it with the script (which will move it to ~/.age/keys.txt)
./age-key-setup.sh import age-key-export.txt
```

The file should look like:
```
# created: YYYY-MM-DDThh:mm:ss-ZZ:ZZ
# public key: age1xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
AGE-SECRET-KEY-1XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
```

#### Working with Encrypted Configuration

The private configuration workflow is similar to ansible-vault - the unencrypted version never persists on disk outside of temporary files during editing.

```bash
# Edit your encrypted configuration
./manage-secrets.sh edit

# View the decrypted content without saving to disk
./manage-secrets.sh view

# Validate YAML syntax
./manage-secrets.sh validate

# Run the setup directly
./manage-secrets.sh setup
```

### 4. Main Setup

Once prerequisites and secrets are configured, run the full setup:

```bash
./setup.sh
```

This script:
1. Loads your configuration (decrypting as needed)
2. Installs and configures all tools specified in your configuration
3. Sets up your development environment according to preferences

## Using Existing Encrypted Configuration

If you're setting up on a new machine and already have an encrypted `private.yml` file in your repository, follow these steps:

### 1. Export Your Age Key from Original Machine

On your original machine:

```bash
# Export your Age key
./age-key-setup.sh export
```

This will create an `age-key-export.txt` file. Transfer this file securely to your new machine.

### 2. Clone and Bootstrap on New Machine

Once you've transferred the key file to your new machine:

```bash
# Clone your repository
git clone https://github.com/yourusername/dev-env-setup.git
cd dev-env-setup

# Run bootstrap to install prerequisites
./bootstrap.sh
```

### 3. Import Your Age Key

```bash
# Import your Age key (this will automatically delete the import file afterward)
./age-key-setup.sh import /path/to/age-key-export.txt
```

### 4. Run Setup

You can now run the setup directly:

```bash
# Run setup using the existing encrypted configuration
./setup.sh
```

Or you can first verify that decryption works:

```bash
# View the decrypted configuration
./manage-secrets.sh view

# Then run setup
./setup.sh
```

## Configuration Options

The setup is driven by two configuration files:

### Public Configuration (public.yml)

Contains non-sensitive settings:
- Shell preferences
- Nix packages
- Homebrew packages
- Editor configurations
- Appearance settings
- Logging level

Example:
```yaml
default_shell: "fish"
install_nvchad: true
nix_packages:
  - "nixpkgs#fish"
  - "nixpkgs#neovim"
log_level: "info"
```

### Private Configuration (private.yml)

Contains sensitive information (always encrypted):
- Git user details
- SSH configuration
- GitHub access tokens
- Dotfiles repository URL

Example (before encryption):
```yaml
git_user:
  name: "Your Name"
  email: "your.email@example.com"
dotfiles:
  repo: "https://github.com/yourusername/dotfiles.git"
```

## Logging

The scripts use a centralized logging system for consistent output across all components.

### Log Levels

You can control the verbosity by setting the log level in `public.yml`:

| Level | Description |
|-------|-------------|
| debug | Most verbose - shows all details including debugging information |
| info  | Standard level - shows regular progress information (default) |
| warn  | Limited output - shows only warnings and errors |
| error | Minimal output - shows only errors |

Example:
```yaml
# In public.yml
log_level: "debug"  # For more detailed output
```

You can also temporarily override the log level:
```bash
# Override for a single command
CURRENT_LOG_LEVEL=0 ./bootstrap.sh  # 0=debug, 1=info, 2=warn, 3=error
```

## Advanced Usage

### Adding Custom Tools

Edit `public.yml` to add additional packages:

```yaml
nix_packages:
  - "nixpkgs#fish"
  - "nixpkgs#your-package"
  
brew_packages:
  - "your-brew-package"
```

### Using with Dotfiles

Configure your dotfiles repository in the private configuration:

```yaml
# In private.yml (before encryption)
dotfiles:
  repo: "https://github.com/yourusername/dotfiles.git"
  branch: "main"
  apply: true
```

### Team Onboarding

When a new team member wants to use this repository:

1. They should run the bootstrap script to install prerequisites
2. Generate their own Age key with `./age-key-setup.sh`
3. Update the `.sops.yaml` file to include their Age public key
4. Re-encrypt the `private.yml` file to allow them access

## Troubleshooting

If you encounter issues:

1. Check the logs for error messages
2. Increase logging verbosity:
   ```yaml
   # In public.yml
   log_level: "debug"
   ```
3. Ensure all prerequisites are installed:
   ```bash
   ./bootstrap.sh
   ```
4. Verify your Age key is properly set up:
   ```bash
   ./age-key-setup.sh env
   ```
5. Validate your configuration:
   ```bash
   ./manage-secrets.sh validate
   ```

## Components

* `bootstrap.sh` - Installs required prerequisites
* `age-key-setup.sh` - Sets up Age encryption keys
* `manage-secrets.sh` - Manages encrypted private configuration
* `load-config.sh` - Loads and processes configuration files
* `setup.sh` - Wrapper that runs the main setup process
* `dev-env-setup.sh` - Main setup script
* `logging.sh` - Centralized logging module

## License

[Your license information here]

## Acknowledgments

[Any acknowledgments or credits]