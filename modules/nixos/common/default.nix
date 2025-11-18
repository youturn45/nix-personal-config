{
  myLib,
  myvars,
  pkgs,
  ...
}: {
  imports = myLib.collectModulesRecursively ./.;

  system.stateVersion = "24.11";

  # Enable flakes and nix-command globally
  nix.settings = {
    experimental-features = ["nix-command" "flakes"];
    trusted-users = [myvars.username];
  };

  # User configuration
  users.users.${myvars.username} = {
    isNormalUser = true;
    description = myvars.userfullname;
    extraGroups = ["wheel" "networkmanager" "video" "audio"];
    shell = pkgs.zsh;
  };

  # Enable zsh system-wide
  programs.zsh.enable = true;

  # Enable SSH agent system-wide
  programs.ssh.startAgent = true;

  # Enable SSH daemon
  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = true;
      PermitRootLogin = "yes";
    };
  };

  # Enable display manager and session management
  services.xserver = {
    enable = true;
    displayManager.lightdm.enable = true;
    desktopManager.xfce.enable = true;
  };

  # Enable D-Bus
  services.dbus.enable = true;
}
