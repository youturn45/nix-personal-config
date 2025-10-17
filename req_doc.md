# Shared Fonts Configuration Requirements

## Goal
- [ ] Ensure the `fonts.packages` configuration currently living in `modules/darwin/system-settings.nix` is shared by both nix-darwin and NixOS hosts.

## Background
The macOS system module defines the desired font packages, but NixOS builds import only `modules/common` and do not see that list. Both platforms already share `modules/common`, which is auto-imported via `myLib.collectModulesRecursively`.

## Tasks
1. **Extract shared module**
   - [ ] Create `modules/common/fonts.nix`.
   - [ ] Move the existing font package list from `modules/darwin/system-settings.nix` into the new module.
   - [ ] Expose it as:
     ```nix
     { pkgs, ... }: {
       fonts.packages = with pkgs; [ ... ];
     }
     ```
     (Keep the current package list intact.)
   - Because `modules/common/default.nix` imports everything in that directory, no extra wiring is required.
2. **Clean darwin module**
   - [ ] Delete the now-duplicated `fonts = { packages = ...; };` block from `modules/darwin/system-settings.nix`.
   - [ ] Confirm no other Darwin-only overrides depend on that attribute.
3. **Validation**
   - [ ] Run `just fmt` to keep formatting consistent.
   - [ ] For macOS: `just safe-build` (or at least `just build-test`) to confirm the darwin configuration still evaluates.
   - [ ] For NixOS: `sudo nixos-rebuild test --flake .` (or `build` if switching is not desired) to verify the fonts are picked up.
4. **Optional follow-ups**
   - [ ] Check whether any additional font-related options (e.g. `fonts.enableDefaultPackages`) are needed for Linux hosts.
   - [ ] Document the shared fonts location in repository docs if this is a common customization point.

## Notes
- No changes are needed in `flake.nix`; both host types already load `modules/common`.
- If additional platform-specific fonts are required later, add per-platform overrides after the shared module is in place.

