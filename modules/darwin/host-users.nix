{myvars, ...} @ args:
#############################################################
#
#  Host & Users configuration
#
#############################################################
{
  # Hostname is now set in individual host configurations
  # networking.hostName is set in hosts/*.nix files
  # networking.computerName and NetBIOSName will follow the hostName automatically

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
