{pkgs-stable, ...}: {
  programs.vscode = {
    enable = true;
    # Swap to pkgs-stable.vscodium if you prefer VSCodium.
    package = pkgs-stable.vscode;

    profiles.default.extensions =
      (with pkgs-stable.vscode-extensions; [
        bbenoist.nix
        catppuccin.catppuccin-vsc
        catppuccin.catppuccin-vsc-icons
        esbenp.prettier-vscode
        ms-python.python
      ])
      ++
      # Add marketplace-only extensions here if needed.
      # Example:
      # (pkgs-stable.vscode-utils.extensionsFromVscodeMarketplace [
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
