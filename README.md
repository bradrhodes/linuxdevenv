# Linux Development Environment Setup Playbook

This Ansible playbook automates the setup of a complete Linux development environment with:

- Nix package manager
- Shell configuration (Fish shell with plugins)
- Git setup
- SSH key management
- Development tools
- Editor configuration (Neovim with NvChad)
- TMUX with plugins
- Nerd Fonts
- Dotfiles management with Chezmoi

## Requirements

- Ansible 2.9+
- A Debian/Ubuntu-based Linux distribution (other distros may work but are not fully tested)
- Internet connection

## Setup

1. Clone this repository:
   ```
   git clone https://github.com/yourusername/dev-setup.git
   cd dev-setup
   ```

2. Edit the configuration files:
   - `group_vars/all/public.yml` - Non-sensitive configuration
   - `group_vars/all/private.yml` - Sensitive configuration (encrypt with ansible-vault)

3. Encrypt your private configuration:
   ```
   ansible-vault encrypt group_vars/all/private.yml
   ```

## Usage

### Two-Phase Installation (Recommended)

For the best experience, run the setup in two phases with a terminal restart in between:

```bash
# Phase 1: Set up base environment (package managers, shell)
ansible-playbook -i inventory.ini phase1-base.yml --ask-become-pass

# Exit your terminal completely and open a new terminal

# Phase 2: Install and configure tools
ansible-playbook -i inventory.ini phase2-tools.yml --ask-become-pass
```

This approach ensures that environment changes from Phase 1 (like new PATH entries) are properly loaded before running Phase 2.

### All-in-One Installation

You can also run everything in one command, but you might need to run it multiple times:

```bash
ansible-playbook -i inventory.ini dev-setup.yml --ask-become-pass
```

After running, exit your terminal, open a new one, and run it again to ensure all tools are properly installed.

### Running Specific Parts

You can use tags to run specific parts of the playbook:

```
ansible-playbook -i inventory.ini phase2-tools.yml --ask-become-pass --tags "git,ssh"
```

Available tags:
- `common` - Common system packages
- `git` - Git configuration
- `ssh` - SSH key management
- `nix` - Nix package manager setup
- `homebrew` - Homebrew package manager setup
- `python` - Python tools setup
- `shell` - Shell configuration
- `editors` - Editor setup (Neovim)
- `tmux` - TMUX setup
- `fonts` - Nerd font installation
- `dotfiles` - Dotfiles management with Chezmoi
- `debug` - Debug tasks (add `-v` for verbose output)

## Structure

```
.
├── dev-setup.yml (wrapper playbook)
├── phase1-base.yml (phase 1 - environment setup) 
├── phase2-tools.yml (phase 2 - tools installation)
├── tasks/
│   └── load_config.yml (configuration loading)
├── group_vars/
│   └── all/
│       ├── public.yml (non-sensitive configuration)
│       └── private.yml (sensitive configuration)
└── roles/
    ├── common/ (system packages)
    ├── git/ (git configuration)
    ├── ssh/ (SSH key management)
    ├── nix/ (Nix package manager)
    ├── homebrew/ (Homebrew package manager)
    ├── python/ (Python tools & utilities)
    ├── shell/ (shell configuration)
    ├── editors/ (Neovim setup)
    ├── tmux/ (TMUX configuration)
    ├── fonts/ (Nerd font installation)
    └── dotfiles/ (dotfiles management)
```

## Customization

Customize your setup by editing the configuration files before running the playbook:

- `public.yml` - Packages to install, shell plugins, etc.
- `private.yml` - Git user info, SSH key settings, dotfiles repo URL

## License

MIT