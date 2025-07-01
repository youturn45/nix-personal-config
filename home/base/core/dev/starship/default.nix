# Simplified starship config for cross-platform compatibility
{
  pkgs,
  ...
}: {
  programs.starship = {
    enable = true;

    enableBashIntegration = true;
    enableZshIntegration = true;

    settings = {
      # Add username and hostname
      username = {
        show_always = true;
        style_user = "bold blue";
        style_root = "bold red";
        format = "[$user]($style)";
      };
      
      hostname = {
        ssh_only = false;
        format = "[@$hostname](bold green) ";
      };

      # Enhanced character
      character = {
        success_symbol = "[➜](bold green)";
        error_symbol = "[➜](bold red)";
        vimcmd_symbol = "[🔒](bold yellow)";
      };

      # Directory
      directory = {
        format = "📁 [$path]($style)[$read_only]($read_only_style) ";
        style = "bold cyan";
        read_only = "🔒";
        truncation_length = 3;
        truncate_to_repo = true;
      };

      # Git
      git_branch = {
        symbol = "🌱 ";
        format = "[$symbol$branch]($style) ";
        style = "bold purple";
      };

      format = "$username$hostname$line_break$directory$git_branch$character";
    };
  };
}