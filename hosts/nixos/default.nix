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
      ../../modules/nixos # NixOS modules (imports common)

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
        home-manager.users.${myvars.username} = import ../../home/nixos;
        home-manager.backupFileExtension = "backup";
        home-manager.sharedModules = [
          specialArgs.nixvim.homeManagerModules.nixvim
        ];
      }
    ];
  }
