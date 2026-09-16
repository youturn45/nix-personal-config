{
  ghostty,
  pkgs-stable,
  ...
}: {
  home.packages = [
    ghostty.packages.${pkgs-stable.stdenv.hostPlatform.system}.default
  ];
}
