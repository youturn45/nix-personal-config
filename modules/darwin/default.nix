{
  myLib,
  vars,
  ...
}: {
  imports =
    [
      ../common # Import common modules shared with NixOS
    ]
    ++ (myLib.collectModulesRecursively ./.); # Import Darwin-specific modules

  time.timeZone = vars.timeZone;
}
