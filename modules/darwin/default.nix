{
  # agenix, -- DISABLED, see modules/common/_secrets.nix for how to re-enable
  myLib,
  vars,
  ...
}: {
  imports =
    [
      # agenix.darwinModules.default # DISABLED, see modules/common/_secrets.nix
      ../common # Import common modules shared with NixOS
    ]
    ++ (myLib.collectModulesRecursively ./.); # Import Darwin-specific modules
}
