{
  # agenix, -- DISABLED, see modules/common/_secrets.nix for how to re-enable
  myLib,
  vars,
  ...
}: {
  imports =
    [
      # agenix.nixosModules.default # DISABLED, see modules/common/_secrets.nix
      ../common # Import common modules shared with Darwin
    ]
    ++ (myLib.collectModulesRecursively ./.); # Import any additional NixOS modules
}
