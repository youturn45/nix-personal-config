{ myLib, ... }:

{
  imports = myLib.collectModulesRecursively ./.;
}
