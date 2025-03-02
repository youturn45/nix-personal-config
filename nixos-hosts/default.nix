{ lib, specialArgs, }:

let
  mkNixosHost = { hostname, system, modules ? [ ] }:
    lib.nixosSystem {
      inherit specialArgs system;
      modules = modules ++ [
        ../modules/common # NOTE shared by nixos and nix-darwin
        ../modules/nixos/common # shared by bare-metal and vm nixos machines
        { networking.hostName = hostname; }
        (lib.path.append ./. hostname) # NOTE config specific to this host
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
      ../modules/nixos/vm # only for nixos vm
    ];
  };

  # anotherVm = mkNixosHost { ... };
}
