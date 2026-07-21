{myLib, ...}: {
  # NightOwl server home — lean dev baseline + heavy server-only tools.
  # Drop server-only home modules (media, tex, ...) directly in this folder;
  # they are collected automatically and never reach the laptop home.
  imports =
    [
      ../../default.nix # common home baseline (shared with laptops)
    ]
    ++ (myLib.collectModulesRecursively ./.) # server-only modules in this folder
    ++ (myLib.collectModulesRecursively ../gui);
}
