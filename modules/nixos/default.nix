{
  myLib,
  vars,
  ...
}: {
  imports =
    [
      ../common # Import common modules shared with Darwin
      ./common # Import NixOS-specific common modules
    ]
    ++ (myLib.collectModulesRecursively ./.); # Import any additional NixOS modules
}
