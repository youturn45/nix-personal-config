{
  ghostty,
  pkgs,
  ...
}: {
  home.packages = [
    ghostty.packages.${pkgs.stdenv.hostPlatform.system}.default
  ];
}
