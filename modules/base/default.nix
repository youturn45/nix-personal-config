{ myLib, ... }:

{
  imports = myLib.collectModulesRecursively ./.;

  time.timeZone = "Asia/Shanghai";
}
