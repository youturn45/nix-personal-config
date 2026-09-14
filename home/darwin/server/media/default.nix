{pkgs-stable, ...}: {
  home.packages = with pkgs-stable; [
    ffmpeg
    imagemagick
    graphviz
    viu
  ];
}
