{ lib, ... }:

{
  # Explicitly disable GRUB to prevent conflicts with systemd-boot
  boot.loader.grub.enable = lib.mkForce false;
}