{
  lib,
  specialArgs,
}: let
  # Get inputs from specialArgs
  inherit (specialArgs) home-manager myvars;
in
  lib.nixosSystem {
    inherit specialArgs;
    system = "x86_64-linux";
    modules = [
      # Hardware configuration
      ./hardware-configuration.nix

      # System modules
      ../../modules/common # NOTE shared by nixos and nix-darwin
      ../../modules/_nixos/common # shared by bare-metal and vm nixos machines

      # Hostname
      {
        networking.hostName = "nixos";
      }

      # Add Home Manager
      home-manager.nixosModules.home-manager
      {
        home-manager.useGlobalPkgs = true;
        home-manager.useUserPackages = true;
        home-manager.extraSpecialArgs = specialArgs;
        home-manager.users.${myvars.username} = lib.mkForce {
          imports = [
            ../../home/base/core.nix
            ../../home/base/dev-tools/npm
            ../../home/base/dev-tools/git
            ../../home/base/terminal/starship
            ../../home/base/terminal/shells
            ../../home/base/editors/neovim
            ../../home/base/python
          ];
          home.stateVersion = "25.05";
          home.packages = with specialArgs.pkgs; [
            # Only essential packages for live system
            curl
            wget
            htop
            tmux
            openssh
          ];
        };
        home-manager.backupFileExtension = "backup";
        home-manager.sharedModules = [
          specialArgs.nixvim.homeManagerModules.nixvim
        ];
      }
    ];
  }
