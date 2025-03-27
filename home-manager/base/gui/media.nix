{
  pkgs,
  config,
  ...
}:
# processing audio/video
{
  home.packages = with pkgs; [
    # images
    viu # Terminal image viewer with native support for iTerm and Kitty
    imagemagick
    graphviz
  ];
}
