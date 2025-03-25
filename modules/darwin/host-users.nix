{
  myvars,
  ...
} @ args:
#############################################################
#
#  Host & Users configuration
#
#############################################################
{
  networking.hostName = myvars.hostname;
  networking.computerName = myvars.hostname;
  system.defaults.smb.NetBIOSName = myvars.hostname;

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users."${myvars.username}" = {
    home = "/Users/${myvars.username}";
    description = myvars.username;
  };

  # home-manager.users."${username}" = { pkgs, ... }: {
  #   home.packages = [ pkgs.atool pkgs.httpie pkgs.cowsay];
  #   programs.bash.enable = true;

  # The state version is required and should stay at the version you
  # originally installed.
  # home.stateVersion = "25.05";
  # };

  # nix.settings.trusted-users = [username];
}
