{
  pkgs,
  ...
}: {
  programs.vscode = {
    enable = true;
    # Swap to pkgs.vscodium if you prefer VSCodium.
    package = pkgs.vscode;

    profiles.default.extensions =
      (with pkgs.vscode-extensions; [
        bbenoist.nix
        catppuccin.catppuccin-vsc
        catppuccin.catppuccin-vsc-icons
        esbenp.prettier-vscode
        ms-python.python
      ])
      ++
      # Add marketplace-only extensions here if needed.
      # Example:
      # (pkgs.vscode-utils.extensionsFromVscodeMarketplace [
      #   {
      #     name = "copilot";
      #     publisher = "GitHub";
      #     version = "1.300.0";
      #     sha256 = "<fill-me>";
      #   }
      # ])
      [];
  };
}
