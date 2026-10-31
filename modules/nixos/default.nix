{
  agenix,
  myLib,
  vars,
  ...
}: {
  imports =
    [
      agenix.nixosModules.default
      ../common # Import common modules shared with Darwin
    ]
    ++ (myLib.collectModulesRecursively ./.); # Import any additional NixOS modules
}
