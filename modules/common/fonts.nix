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

    # Google Noto CJK fonts - comprehensive Chinese/Japanese/Korean support
    noto-fonts-cjk-sans # 思源黑体 (Google's version)
    noto-fonts-cjk-serif # 思源宋体 (Google's version)

    # Additional Chinese fonts
    shanggu-fonts # 上古字体 - archaic Chinese characters
  ];
}
