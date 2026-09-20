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
    nixpkgs-darwin = {
      url = "https://github.com/NixOS/nixpkgs/archive/refs/heads/nixpkgs-26.05-darwin.tar.gz";
    };
    nixpkgs-nixos = {
      url = "https://github.com/NixOS/nixpkgs/archive/refs/heads/nixos-26.05.tar.gz";
    };
    nixpkgs-unstable = {
      url = "https://github.com/NixOS/nixpkgs/archive/refs/heads/nixpkgs-unstable.tar.gz";
    };
    nix-darwin = {
      url = "https://github.com/nix-darwin/nix-darwin/archive/refs/heads/nix-darwin-26.05.tar.gz";
      inputs.nixpkgs.follows = "nixpkgs-darwin";
    };

    # home-manager, used for managing user configuration
    home-manager = {
      url = "https://github.com/nix-community/home-manager/archive/refs/heads/release-26.05.tar.gz";
      inputs.nixpkgs.follows = "nixpkgs-darwin";
    };

    # nix-homebrew, used for managing homebrew packages
    nix-homebrew = {
      url = "github:zhaofengli/nix-homebrew";
    };

    # haumea, used for managing flake imports
    haumea = {
      url = "github:nix-community/haumea/v0.2.2";
      inputs.nixpkgs.follows = "nixpkgs-darwin";
    };

    # ghostty, used for managing ghostty packages
    ghostty = {
      url = "github:ghostty-org/ghostty";
    };

    # codex-cli-nix, hourly-updated OpenAI Codex CLI package
    codex-cli-nix = {
      url = "github:sadjow/codex-cli-nix";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };

    claude-code = {
      url = "https://github.com/sadjow/claude-code-nix/archive/refs/heads/main.tar.gz";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };

    # agenix, used for managing secrets -- DISABLED, see modules/common/_secrets.nix
    # for why and how to re-enable. Uncomment this block as step one of that.
    # agenix = {
    #   url = "github:ryantm/agenix";
    #   inputs.nixpkgs.follows = "nixpkgs-darwin";
    # };

    # nixvim, used for managing neovim configuration
    nixvim = {
      url = "https://github.com/nix-community/nixvim/archive/refs/heads/nixos-26.05.tar.gz";
      inputs.nixpkgs.follows = "nixpkgs-darwin";
    };

    # nur-ryan4yin, custom packages used from ryan4yin
    nur-ryan4yin.url = "github:ryan4yin/nur-packages";
  };

  outputs = inputs @ {
    self,
    nixpkgs-darwin,
    nixpkgs-nixos,
    nixpkgs-unstable,
    nur-ryan4yin,
    nix-darwin,
    nix-homebrew,
    home-manager,
    haumea,
    ghostty,
    nixvim,
    # agenix, -- DISABLED, uncomment along with the input block above
    ...
  }: let
    inherit (nixpkgs-darwin) lib;
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
    # No `pkgs` here deliberately -- the canonical `pkgs` module argument
    # (needed by nix-darwin/home-manager's own built-in modules, not just
    # ours) is set via the `nixpkgs.pkgs` option instead, in mkDarwinHost /
    # mkNixosHost below. Our own modules use pkgs-stable/pkgs-unstable only.
    mkSpecialArgs = system: {
      inherit myvars myLib nur-ryan4yin ghostty home-manager nixvim; # add `agenix` back here too when re-enabling
      inherit (inputs) claude-code codex-cli-nix;
      vars = myvars; # Alias for modules expecting 'vars'

      pkgs-unstable = mkPkgs inputs.nixpkgs-unstable system;
      pkgs-stable = mkPkgs inputs.nixpkgs-darwin system;
    };

    # Darwin-specific specialArgs (using macOS system from myvars)
    darwinSpecialArgs = mkSpecialArgs myvars.system;

    # Linux-specific specialArgs for NixOS (no `pkgs` here either, same reason as above)
    nixosSpecialArgs = {
      inherit myvars myLib nur-ryan4yin ghostty home-manager nixvim; # add `agenix` back here too when re-enabling
      inherit (inputs) claude-code codex-cli-nix;
      vars = myvars; # Alias for modules expecting 'vars'

      pkgs-unstable = mkPkgs inputs.nixpkgs-unstable "x86_64-linux";
      pkgs-stable = mkPkgs inputs.nixpkgs-nixos "x86_64-linux";
    };

    mkNixosHost = {
      hostModule,
      hardwareModule ? null,
    }:
      nixpkgs-nixos.lib.nixosSystem {
        specialArgs = nixosSpecialArgs;
        system = "x86_64-linux";
        modules =
          (lib.optionals (hardwareModule != null) [
            hardwareModule
          ])
          ++ [
            {
              # Canonical `pkgs` for this system -- needed by nix-darwin/home-manager's
              # own built-in modules, not just ours (which use pkgs-stable/pkgs-unstable
              # from specialArgs instead). Same source as nixosSpecialArgs.pkgs-stable.
              # allowUnfree is already baked in at construction time (see mkPkgs) --
              # setting nixpkgs.config.* here too would conflict: NixOS asserts against
              # combining an externally-built `nixpkgs.pkgs` with `nixpkgs.config.*`.
              nixpkgs.pkgs = nixosSpecialArgs.pkgs-stable;
            }

            hostModule
            ./modules/nixos
            home-manager.nixosModules.home-manager
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.extraSpecialArgs = nixosSpecialArgs;
              home-manager.users.${myvars.username} = import ./home/nixos;
              home-manager.backupFileExtension = "backup";
              home-manager.sharedModules = [
                nixvim.homeModules.nixvim
              ];
            }
          ];
      };

    nixosOzymandias = mkNixosHost {
      hostModule = ./hosts/nixos/ozymandias/configuration.nix;
      hardwareModule = ./hosts/nixos/ozymandias/hardware-configuration.nix;
    };

    nixosIso = nixosOzymandias.extendModules {
      modules = [
        "${nixpkgs-nixos}/nixos/modules/installer/cd-dvd/installation-cd-minimal.nix"
      ];
    };

    mkDarwinHost = {
      hostname,
      hmModule ? ./home/darwin,
    }:
      nix-darwin.lib.darwinSystem {
        specialArgs = darwinSpecialArgs;
        system = "${myvars.system}";
        modules = [
          {
            # Canonical `pkgs` for this system -- needed by nix-darwin/home-manager's
            # own built-in modules, not just ours (which use pkgs-stable/pkgs-unstable
            # from specialArgs instead). Same source as darwinSpecialArgs.pkgs-stable.
            nixpkgs.pkgs = darwinSpecialArgs.pkgs-stable;
          }
          ./hosts/darwin/${hostname}.nix
          ./modules/darwin # Darwin modules (imports common)
          home-manager.darwinModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.extraSpecialArgs = darwinSpecialArgs;
            home-manager.users.${myvars.username} = import hmModule;
            home-manager.backupFileExtension = "backup";
            home-manager.sharedModules = [
              nixvim.homeModules.nixvim
            ];
          }
        ];
      };
  in {
    formatter = lib.genAttrs ["aarch64-darwin" "x86_64-darwin" "x86_64-linux" "aarch64-linux"] (
      system: (mkPkgs nixpkgs-unstable system).alejandra
    );
    darwinConfigurations = {
      Rorschach = mkDarwinHost {hostname = "Rorschach";};
      NightOwl = mkDarwinHost {
        hostname = "NightOwl";
        hmModule = ./home/darwin/server;
      };
      SilkSpectre = mkDarwinHost {hostname = "SilkSpectre";};
    };
    nixosConfigurations = {
      ozymandias = nixosOzymandias;
      ozymandias-iso = nixosIso;
    };
    packages.x86_64-linux.ozymandias-iso = nixosIso.config.system.build.isoImage;
  };
}
