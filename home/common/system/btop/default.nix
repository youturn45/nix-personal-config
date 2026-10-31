{
  pkgs-stable,
  ...
}: let
  theme = pkgs-stable.catppuccin.override {
    variant = "mocha";
    themeList = ["btop"];
  };
in {
  xdg.configFile."btop/themes".source = "${theme}/btop";

  # replacement of htop/nmon
  programs.btop = {
    enable = true;
    settings = {
      color_theme = "catppuccin_mocha";
      theme_background = false; # make btop transparent
    };
  };
}
