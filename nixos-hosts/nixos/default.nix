{ myLib, ... }:

{
  imports = [
    ./hardware-configuration.nix
  ] ++ myLib.collectModulesRecursively ./.;
}