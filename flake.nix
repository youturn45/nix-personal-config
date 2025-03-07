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
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    
    nix-darwin = {
      url = "github:lnl7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };
 
    # home-manager, used for managing user configuration
    home-manager = {
      url = "github:nix-community/home-manager/master";
      # url = "github:nix-community/home-manager/release-24.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-homebrew.url = "github:zhaofengli/nix-homebrew";
    nix-homebrew.inputs.nixpkgs.follows = "nixpkgs";

    ghostty = {
      url = "github:ghostty-org/ghostty";
    };
    nur-ryan4yin.url = "github:ryan4yin/nur-packages";

    haumea = {
      url = "github:nix-community/haumea/v0.2.2";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
 
  outputs = inputs @ { 
    self, 
    nixpkgs, 
    nix-darwin, 
    nix-homebrew, 
    home-manager, 
    haumea,
    ... }:
  let 
    inherit (nixpkgs) lib;
    myLib = import ./my-lib { inherit lib; haumeaLib = haumea.lib; };
    myvars = import ./vars {inherit lib;};

    system = "aarch64-darwin";
    hostname = "Rorschach";
    
    specialArgs =
      inputs
      // {
        inherit myvars myLib;
        # Add both username and hostname to specialArgs
        inherit (myvars) username useremail userfullname;
        inherit hostname system;  # Add hostname to specialArgs
        # use unstable branch for some packages to get the latest updates
        pkgs-unstable = import inputs.nixpkgs-unstable {
          inherit system;
          config.allowUnfree = true;
        };
        pkgs-stable = import inputs.nixpkgs {
          inherit system;
          config.allowUnfree = true;
        };
      };
  in {
    darwinConfigurations."${hostname}" = nix-darwin.lib.darwinSystem {
      inherit system specialArgs;
      modules = [
        ./modules/common # NOTE shared by nixos and nix-darwin
        ./modules/darwin
        #./modules/darwin/nix-core.nix
        #./modules/darwin/system.nix
        #./modules/darwin/apps.nix
        #./modules/darwin/host-users.nix
        # ./modules/homebrew-mirror.nix # homebrew mirror, comment it if you do not need it
        home-manager.darwinModules.home-manager
        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.extraSpecialArgs = specialArgs;
          home-manager.users.${specialArgs.username} = import ./home;
          home-manager.backupFileExtension = "backup";
        }
      ];
    };
    nixosConfigurations = import ./nixos-hosts { inherit lib specialArgs; };
  };
}
