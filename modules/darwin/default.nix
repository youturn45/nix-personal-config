{ myLib, vars, ... }:

{
  imports = myLib.collectModulesRecursively ./.;
  time.timeZone = vars.timeZone;
}
