{
  description = "Nix configuration";

  # the nixConfig here only affects the flake itself, not the system configuration!
  /*nixConfig = {
    substituters = [
      # Query the mirror of USTC first, and then the official cache.
      "https://mirrors.ustc.edu.cn/nix-channels/store"
      "https://cache.nixos.org"
    ];
  };*/

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs";
 
    darwin.url = "github:lnl7/nix-darwin";
    darwin.inputs.nixpkgs.follows = "nixpkgs";
 
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    nix-homebrew.url = "github:zhaofengli/nix-homebrew";
    nix-homebrew.inputs.nixpkgs.follows = "nixpkgs";
  };
 
  outputs = inputs @ { 
    self, 
    nixpkgs, 
    darwin, 
    nix-homebrew, 
    home-manager, 
    ... }:
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
    darwinConfigurations."${hostname}" = darwin.lib.darwinSystem {
      inherit system specialArgs;
      modules = [
        ./modules/nix-core.nix
        ./modules/system.nix
        ./modules/apps.nix
        ./modules/host-users.nix
        # ./modules/homebrew-mirror.nix # homebrew mirror, comment it if you do not need it
        home-manager.darwinModules.home-manager
        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.extraSpecialArgs = specialArgs;
          home-manager.users.${username} = import ./home;
          home-manager.backupFileExtension = "backup";
          
        }
      ];
    };
  };
}
