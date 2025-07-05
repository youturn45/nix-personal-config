# Generic hardware configuration - you need to replace this with your actual hardware-configuration.nix
# Copy from /etc/nixos/hardware-configuration.nix on your NixOS system

{ config, lib, pkgs, modulesPath, ... }:

{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
  ];

  # Boot configuration - adjust for your system
  boot.loader.grub.enable = true;
  boot.loader.grub.device = "/dev/sda"; # Replace with your boot device
  
  # Or if using systemd-boot (UEFI):
  # boot.loader.systemd-boot.enable = true;
  # boot.loader.efi.canTouchEfiVariables = true;

  # Root filesystem - adjust for your system
  fileSystems."/" = {
    device = "/dev/disk/by-label/nixos";
    fsType = "ext4";
  };

  # Swap - adjust if you have swap
  # swapDevices = [ ];

  # Networking
  networking.useDHCP = lib.mkDefault true;
  
  # Hardware settings
  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  
  # Enable common hardware support
  hardware.enableRedistributableFirmware = true;
}