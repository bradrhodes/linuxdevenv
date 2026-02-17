# Add ~/.local/bin to PATH if it exists and is not already present
if test -d ~/.local/bin
    if not contains ~/.local/bin $PATH
        set -x PATH ~/.local/bin $PATH
    end
end

# Add .NET to PATH if not already present
if not contains $DOTNET_ROOT $PATH
    set -x PATH $PATH $HOME/.dotnet
end

# Source Nix daemon Fish profile if it exists
if test -f /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.fish
    source /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.fish
end

# Source /etc/profile via bass (commented out - not needed with Nix environment)
# bass source /etc/profile

# Initialize Homebrew if available
if test -d /home/linuxbrew/.linuxbrew
    eval (/home/linuxbrew/.linuxbrew/bin/brew shellenv)
end

# FZF Fish integration
fzf --fish | source

function clip
    powershell.exe -command '$input | Set-Clipboard'
end
