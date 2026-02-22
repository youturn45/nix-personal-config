{
  lib,
  specialArgs,
}: let
  # Get inputs from specialArgs
  inherit (specialArgs) home-manager myvars;
  mkNixosHost = {
    hostModule,
    hardwareModule ? null,
  }:
    lib.nixosSystem {
      inherit specialArgs;
      system = "x86_64-linux";
      modules =
        (lib.optionals (hardwareModule != null) [
          # Host-specific hardware configuration
          hardwareModule
        ])
        ++ [
          # Allow unfree packages (e.g. vscode) for NixOS + Home Manager eval/build.
          {
            nixpkgs.config.allowUnfree = true;
          }

          # Host-specific module
          hostModule

          # System modules
          ../../modules/nixos # NixOS modules (imports common)

          # Add Home Manager
          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.extraSpecialArgs = specialArgs;
            home-manager.users.${myvars.username} = import ../../home/nixos;
            home-manager.backupFileExtension = "backup";
            home-manager.sharedModules = [
              specialArgs.nixvim.homeModules.nixvim
            ];
          }
        ];
    };
in {
  ozymandias = mkNixosHost {
    hostModule = ./ozymandias/default.nix;
    hardwareModule = ./ozymandias/hardware-configuration.nix;
  };
}
