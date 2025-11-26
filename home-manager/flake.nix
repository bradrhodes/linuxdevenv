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

      # Helper to create home-manager configuration
      mkHome = home-manager.lib.homeManagerConfiguration {
        inherit pkgs;
        modules = [
          ./home.nix
          sops-nix.homeManagerModules.sops
        ];
      };
    in
    {
      # Use homeConfigurations without a username key
      # home-manager will automatically use $USER
      homeConfigurations = {
        bigb = mkHome;
      };
    };
}
