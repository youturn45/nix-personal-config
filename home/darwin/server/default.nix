{myLib, ...}: {
  # NightOwl server home — lean dev baseline + heavy server tools
  imports =
    [
      ../../default.nix
      ../../common/_server/media.nix
    ]
    ++ (myLib.collectModulesRecursively ../gui);
}
