{
  pkgs,
  ghostty,
  ...
}:
###########################################################
#
# Ghostty Configuration
#
###########################################################
{
  programs.ghostty = {
    enable = true;
    package =
      if pkgs.stdenv.isDarwin
      then pkgs.hello # pkgs.ghostty is currently broken on darwin
      else pkgs.ghostty; # the stable version
    # package = ghostty.packages.${pkgs.system}.default; # the latest version
    enableBashIntegration = false;
    installBatSyntax = false;
    enableZshIntegration = true;
    
    # installVimSyntax = true;
    settings = {
      theme = "catppuccin-mocha";

      font-family = "Fira Code";
      font-size = 14;

      background-opacity = 0.9;
      # only supported on macOS;
      background-blur-radius = 5;
      scrollback-limit = 20000;

      # https://ghostty.org/docs/config/reference#command
      #  To resolve issues:
      #    1. https://github.com/ryan4yin/nix-config/issues/26
      #    2. https://github.com/ryan4yin/nix-config/issues/8
      #  Spawn a nushell in login mode via `bash`
      #command = "${pkgs.bash}/bin/bash --login -c 'nu --login --interactive'";
    };
  };
}
