{ lib, specialArgs, }:

let
  # Get inputs from specialArgs
  inherit (specialArgs) home-manager myvars;
  
  mkNixosHost = { hostname, system, modules ? [ ] }:
    lib.nixosSystem {
      inherit specialArgs system;
      modules = modules ++ [
        ../modules/common # NOTE shared by nixos and nix-darwin
        ../modules/_nixos/common # shared by bare-metal and vm nixos machines
        { networking.hostName = hostname; }
        (lib.path.append ./. hostname) # NOTE config specific to this host
        
        # Add Home Manager
        home-manager.nixosModules.home-manager
        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.extraSpecialArgs = specialArgs;
          home-manager.users.${myvars.username} = import ../home;
          home-manager.backupFileExtension = "backup";
        }
      ];
    };
in
{
  # steps to run this vm:
  #   1. nix build .#nixosConfigurations.myVm.config.system.build.vm
  #   2. NIX_DISK_IMAGE=~/myVm.qcow2 ./result/bin/run-myVm-vm
  myVm = mkNixosHost {
    hostname = "myVm";
    system = "x86_64-linux";
    modules = [
      ../modules/_nixos/vm # only for nixos vm
    ];
  };

  # anotherVm = mkNixosHost { ... };
}
