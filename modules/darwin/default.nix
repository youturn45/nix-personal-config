{
  agenix,
  myLib,
  vars,
  ...
}: {
  imports =
    [
      agenix.darwinModules.default
      ../common # Import common modules shared with NixOS
    ]
    ++ (myLib.collectModulesRecursively ./.); # Import Darwin-specific modules
}
