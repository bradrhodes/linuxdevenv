{
  description = "Home Manager configuration for cross-distro development environment";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { nixpkgs, home-manager, sops-nix, ... }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};

      # Get username from environment or use a default
      username = builtins.getEnv "USER";

      # Helper to create home-manager configuration
      mkHome = username: home-manager.lib.homeManagerConfiguration {
        inherit pkgs;
        modules = [
          ./home.nix
          sops-nix.homeManagerModules.sops
        ];
      };
    in
    {
      homeConfigurations = {
        # Dynamic username from $USER environment variable
        ${username} = mkHome username;

        # Fallback for explicit username specification
        # Usage: home-manager switch --flake .#yourname
      };
    };
}
