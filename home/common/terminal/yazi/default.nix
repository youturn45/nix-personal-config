{
  pkgs-stable,
  pkgs-unstable,
  ...
}: let
  # Keep the existing theme revision without depending on NUR's package exports.
  themes = pkgs-stable.fetchFromGitHub {
    owner = "yazi-rs";
    repo = "themes";
    rev = "8abf251851b9b7559f810a65932cd7735b202dfa";
    hash = "sha256-f8Mwacw8FoZ5S0wUdQcmtFZwrxDyabJfL7kPKhmOD1A=";
  };
in {
  # terminal file manager
  programs.yazi = {
    enable = true;
    package = pkgs-unstable.yazi;
    shellWrapperName = "yy";
    # Changing working directory when exiting Yazi
    enableBashIntegration = true;
    enableNushellIntegration = true;
    settings = {
      mgr = {
        show_hidden = true;
        sort_dir_first = true;
      };
    };
  };

  xdg.configFile."yazi/theme.toml".source = "${themes}/catppuccin/mocha.toml";
}
