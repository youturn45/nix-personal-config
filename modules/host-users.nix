{
  username,
  hostname,
  ...
} @ args:
#############################################################
#
#  Host & Users configuration
#
#############################################################
{
  networking.hostName = hostname;
  networking.computerName = hostname;
  system.defaults.smb.NetBIOSName = hostname;

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users."${username}" = {
    home = "/Users/${username}";
    description = username;
  };
  home-manager.users."${username}" = { pkgs, ... }: {
    home.packages = [ pkgs.atool pkgs.httpie pkgs.cowsay];
    programs.bash.enable = true;

  # The state version is required and should stay at the version you
  # originally installed.
  home.stateVersion = "25.05";
  };

  nix.settings.trusted-users = [username];
}
