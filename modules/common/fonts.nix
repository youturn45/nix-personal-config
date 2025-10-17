{pkgs, ...}: {
  # Shared fonts configuration for both nix-darwin and NixOS
  fonts.packages = with pkgs; [
    # Icon fonts
    material-design-icons
    font-awesome
    nerd-fonts.fira-code
    nerd-fonts.jetbrains-mono
    nerd-fonts.space-mono
    maple-mono.NF-CN-unhinted

    # Source fonts with Chinese support
    source-sans
    source-serif
    source-han-sans # 思源黑体
    source-han-serif # 思源宋体
  ];
}
