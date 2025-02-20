{
  description = "Nix configuration";
 
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs";
 
    nix-darwin.url = "github:lnl7/nix-darwin/master";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
 
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    nix-homebrew.url = "github:zhaofengli/nix-homebrew";
    nix-homebrew.inputs.nixpkgs.follows = "nixpkgs";
  };
 
  outputs = inputs @ { self, nixpkgs, nix-darwin, nix-homebrew, home-manager, ... }:
  let
    nixpkgsConfig = {
      config.allowUnfree = true;
    };
  in {
    darwinConfigurations = let
      inherit (inputs.nix-darwin.lib) darwinSystem;
    in {
      machine = darwinSystem {
        system = "aarch64-darwin";
        
        specialArgs = { inherit inputs; };

        modules = [
          {
            nixpkgs = nixpkgsConfig;
            system.stateVersion = 4;
          }
          ./hosts/mbp/configuration.nix
          inputs.home-manager.darwinModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.youturn = import ./home/home.nix;
          }
        ];
      };
    };
  };
}
