{ modulesPath, ... }:

{
  imports = [
    (modulesPath + "/profiles/qemu-guest.nix")
  ];

  # Basic filesystem configuration for VM
  fileSystems."/" = {
    device = "/dev/disk/by-label/nixos";
    fsType = "ext4";
  };

  # Boot configuration for VM
  boot.loader.grub = {
    enable = true;
    device = "/dev/vda"; # First virtual disk in QEMU
  };

  # Enable serial console for VM management
  boot.kernelParams = [ "console=ttyS0" ];
}
