{ myLib, ... }:

{
  imports = myLib.collectModulesRecursively ./.;

  services.getty.autologinUser = "root";
}
