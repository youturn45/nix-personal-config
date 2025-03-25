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
    # official nix pkgs sources
    pkgs = {
      url = "github:nixos/nixpkgs/nixos-unstable";
    };
    pkgs-unstable = {
      url = "github:NixOS/nixpkgs/nixos-unstable";
    };
    pkgs-stable = {
      url = "github:NixOS/nixpkgs/nixos-24.11";
    };
    nix-darwin = {
      url = "github:lnl7/nix-darwin";
      inputs.pkgs.follows = "pkgs";
    };

    # home-manager, used for managing user configuration
    home-manager = {
      url = "github:nix-community/home-manager/master";
      # url = "github:nix-community/home-manager/release-24.11";
      inputs.pkgs.follows = "pkgs";
    };

    # nix-homebrew, used for managing homebrew packages
    nix-homebrew = {
      url = "github:zhaofengli/nix-homebrew";
      inputs.pkgs.follows = "pkgs";
    };

    # haumea, used for managing flake imports
    haumea = {
      url = "github:nix-community/haumea/v0.2.2";
      inputs.pkgs.follows = "pkgs";
    };

    # ghostty, used for managing ghostty packages
    ghostty = {
      url = "github:ghostty-org/ghostty";
    };
    
    # nur-ryan4yin, custom packages used from ryan4yin
    nur-ryan4yin.url = "github:ryan4yin/nur-packages";
  };
 
  outputs = inputs @ { 
    self, 
    pkgs, 
    pkgs-unstable,
    nur-ryan4yin,
    nix-darwin, 
    nix-homebrew, 
    home-manager, 
    haumea,
    ... }:
  let 
    inherit (pkgs) lib;
    myLib = import ./my-lib { inherit lib; haumeaLib = haumea.lib; };
    myvars = import ./vars {}; #{ inherit lib; };
    
    specialArgs = {
      inherit myvars myLib;
      # pkgs.config.allowUnfree = true;
      inherit pkgs pkgs-unstable nur-ryan4yin;
    };

    pkgsConfig = {
      pkgs.config.allowUnfree = true;
      pkgs.hostPlatform = myvars.system;
    };

  in {
    darwinConfigurations."${myvars.hostname}" = nix-darwin.lib.darwinSystem {
      inherit specialArgs;
      modules = [
        pkgsConfig
        ./modules/common # NOTE shared by nixos and nix-darwin
        ./modules/darwin
        # ./modules/homebrew-mirror.nix # homebrew mirror, comment it if you do not need it
        home-manager.darwinModules.home-manager
        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.extraSpecialArgs = specialArgs;
          home-manager.users.${myvars.username} = import ./home;
          home-manager.backupFileExtension = "backup";
        }
      ];
    };
    nixosConfigurations = import ./nixos-hosts { inherit lib specialArgs; };
  };
}