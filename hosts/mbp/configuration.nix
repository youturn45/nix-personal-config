_:
 
{
  services.nix-daemon.enable = true;
 
  users.users.youturn = {
    home = "/Users/youturn";
  };
 
  nix.extraOptions = ''
    auto-optimise-store = true
    experimental-features = nix-command flakes
    extra-platforms = x86_64-darwin aarch64-darwin
  '';
 
  homebrew = {
    enable = true;
 
    casks = [
      "zappy"
    ];
  };
}
