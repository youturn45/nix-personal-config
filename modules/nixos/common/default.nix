{ myLib, ... }:

{
  imports = myLib.collectModulesRecursively ./.;

  system.stateVersion = "24.11";
}
