{
  description = "Nix configuration";
 
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs";
 
    nix-darwin.url = "github:lnl7/nix-darwin";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
 
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    nix-homebrew.url = "github:zhaofengli/nix-homebrew";
    nix-homebrew.inputs.nixpkgs.follows = "nixpkgs";
  };
 
  outputs = inputs @ { self, nixpkgs, nix-darwin, nix-homebrew, home-manager, ... }:
  let 
    # TODO replace with your own username, email, system, and hostname
    username = "youturn";
    useremail = "youturn@gmail.com";
    system = "aarch64-darwin"; # aarch64-darwin or x86_64-darwin
    hostname = "Rorschach";
    specialArgs =
      inputs
      // {
        inherit username useremail hostname;
      };
  in {
    darwinConfigurations."${hostname}" = nix-darwin.lib.darwinSystem {
      inherit system specialArgs;
      modules = [
        {
          nixpkgs.config.allowUnfree = true;
        }
        ./hosts/mbp/configuration.nix
        inputs.home-manager.darwinModules.home-manager
        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.extraSpecialArgs = specialArgs;
          home-manager.users.youturn = import ./home/home.nix;
        }
        ];
      };
    };
  };
}
