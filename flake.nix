{
  description = "Nix configuration";

  # the nixConfig here only affects the flake itself, not the system configuration!
  /*
    nixConfig = {
    substituters = [
      # Query the mirror of USTC first, and then the official cache.
      "https://mirrors.ustc.edu.cn/nix-channels/store"
      "https://cache.nixos.org"
    ];
  };
  */

  inputs = {
    # official nix pkgs sources
    nixpkgs = {
      url = "github:NixOS/nixpkgs/nixos-unstable";
    };
    nixpkgs-unstable = {
      url = "github:NixOS/nixpkgs/nixos-unstable";
    };
    nixpkgs-stable = {
      url = "github:NixOS/nixpkgs/nixos-24.11";
    };
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

    # nix-homebrew, used for managing homebrew packages
    nix-homebrew = {
      url = "github:zhaofengli/nix-homebrew";
    };

    # haumea, used for managing flake imports
    haumea = {
      url = "github:nix-community/haumea/v0.2.2";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # ghostty, used for managing ghostty packages
    ghostty = {
      url = "github:ghostty-org/ghostty";
    };

    # agenix, used for managing secrets
    agenix = {
      url = "github:ryantm/agenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # nixvim, used for managing neovim configuration
    nixvim = {
      url = "github:nix-community/nixvim";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # nur-ryan4yin, custom packages used from ryan4yin
    nur-ryan4yin.url = "github:ryan4yin/nur-packages";
  };

  outputs = inputs @ {
    self,
    nixpkgs,
    nixpkgs-unstable,
    nur-ryan4yin,
    nix-darwin,
    nix-homebrew,
    home-manager,
    haumea,
    ghostty,
    agenix,
    nixvim,
    ...
  }: let
    inherit (nixpkgs) lib;
    myLib = import ./my-lib {
      inherit lib;
      haumeaLib = haumea.lib;
    };
    myvars = import ./vars {inherit lib;};

    # Helper function to create consistent package sets
    mkPkgs = nixpkgs: system:
      import nixpkgs {
        config.allowUnfree = true;
        inherit system;
        hostPlatform = system;
      };

    # Create system-specific specialArgs
    mkSpecialArgs = system: {
      inherit myvars myLib nur-ryan4yin ghostty agenix home-manager nixvim;
      vars = myvars; # Alias for modules expecting 'vars'

      pkgs = mkPkgs inputs.nixpkgs system;
      pkgs-unstable = mkPkgs inputs.nixpkgs-unstable system;
      pkgs-stable = mkPkgs inputs.nixpkgs-stable system;
    };

    # Darwin-specific specialArgs (using macOS system from myvars)
    darwinSpecialArgs = mkSpecialArgs myvars.system;

    # Linux-specific specialArgs for NixOS (without pkgs to avoid warnings)
    nixosSpecialArgs = {
      inherit myvars myLib nur-ryan4yin ghostty agenix home-manager nixvim;
      vars = myvars; # Alias for modules expecting 'vars'

      # Only include alternative package sets, let NixOS manage its own pkgs
      pkgs-unstable = mkPkgs inputs.nixpkgs-unstable "x86_64-linux";
      pkgs-stable = mkPkgs inputs.nixpkgs-stable "x86_64-linux";
    };

    mkDarwinHost = hostname:
      nix-darwin.lib.darwinSystem {
        specialArgs = darwinSpecialArgs;
        system = "${myvars.system}";
        modules = [
          ./hosts/darwin/${hostname}.nix
          ./modules/common # NOTE shared by nixos and nix-darwin
          ./modules/darwin
          # ./modules/homebrew-mirror.nix # homebrew mirror, comment it if you do not need it
          agenix.darwinModules.default
          home-manager.darwinModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.extraSpecialArgs = darwinSpecialArgs;
            home-manager.users.${myvars.username} = import ./home;
            home-manager.backupFileExtension = "backup";
            home-manager.sharedModules = [
              nixvim.homeManagerModules.nixvim
            ];
          }
        ];
      };
  in {
    darwinConfigurations = {
      Rorschach = mkDarwinHost "rorschach";
      NightOwl = mkDarwinHost "NightOwl";
      SilkSpectre = mkDarwinHost "SilkSpectre";
    };
    nixosConfigurations = {
      nixos = import ./hosts/nixos {
        inherit lib;
        specialArgs = nixosSpecialArgs;
      };
    };
  };
}
