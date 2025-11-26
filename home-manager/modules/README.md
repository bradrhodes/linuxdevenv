# Home Manager Modules

This directory contains modular configuration files for different parts of your environment.

## Module Structure

Each module is a self-contained configuration for a specific tool or category:

| Module | Purpose |
|--------|---------|
| `sops.nix` | SOPS/Age secrets management configuration |
| `packages.nix` | All Nix packages to install + environment variables |
| `git.nix` | Git configuration (user, aliases, settings) |
| `fish.nix` | Fish shell configuration (plugins, aliases, functions) |
| `tmux.nix` | Tmux configuration (prefix, plugins, keybindings) |
| `neovim.nix` | Neovim basic configuration |
| `starship.nix` | Starship prompt configuration |
| `activation.nix` | Activation scripts (LazyVim, fonts, SSH keys) |

## How It Works

The main `../home.nix` file imports all these modules:

```nix
imports = [
  ./modules/sops.nix
  ./modules/packages.nix
  ./modules/git.nix
  # ... etc
];
```

Each module is evaluated and merged into the final Home Manager configuration.

## Making Changes

### Add a Package
Edit `packages.nix`:
```nix
home.packages = with pkgs; [
  existing-package
  new-package     # ← Add here
];
```

### Change Git Config
Edit `git.nix`:
```nix
programs.git = {
  aliases = {
    myalias = "!echo hello";  # ← Add here
  };
};
```

### Add Fish Alias
Edit `fish.nix`:
```nix
shellAliases = {
  myalias = "echo hello";  # ← Add here
};
```

## Benefits of Modular Structure

✅ **Organized** - Easy to find specific configurations
✅ **Maintainable** - Each file has a single responsibility
✅ **Shareable** - Can share individual modules between machines
✅ **Conditional** - Easy to conditionally import modules per machine
✅ **Readable** - Smaller files are easier to understand

## Advanced: Per-Machine Modules

You can create machine-specific modules:

```nix
# In home.nix
imports = [
  ./modules/packages.nix
  ./modules/git.nix
] ++ (if builtins.pathExists ./modules/machine-specific.nix
      then [ ./modules/machine-specific.nix ]
      else []);
```

Or use conditionals based on hostname:

```nix
imports = [
  ./modules/packages.nix
] ++ (if config.home.homeDirectory == "/home/work"
      then [ ./modules/work-specific.nix ]
      else [ ./modules/personal-specific.nix ]);
```
