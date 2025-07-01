{ myLib, myvars, pkgs, ... }:

{
  imports = myLib.collectModulesRecursively ./.;

  system.stateVersion = "24.11";

  # User configuration
  users.users.${myvars.username} = {
    isNormalUser = true;
    description = myvars.userfullname;
    extraGroups = [ "wheel" "networkmanager" "video" "audio" ];
    shell = pkgs.zsh;
  };

  # Enable zsh system-wide
  programs.zsh.enable = true;

  # Enable SSH daemon
  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = true;
      PermitRootLogin = "yes";
    };
  };
}
