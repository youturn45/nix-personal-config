{
  pkgs,
  nur-ryan4yin,
  ...
}: {
  programs.starship = {
    enable = true;

    enableBashIntegration = true;
    enableZshIntegration = true;
    enableNushellIntegration = true;

    settings =
      {
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

        # Add timestamp
        time = {
          disabled = false;
          format = "🕐 [$time]($style) ";
          style = "bold yellow";
          time_format = "%H:%M:%S";
        };

        # Enhanced character with emojis
        character = {
          success_symbol = "[➜](bold green)";
          error_symbol = "[➜](bold red)";
          vimcmd_symbol = "[🔒](bold yellow)";
        };

        # Directory with emoji
        directory = {
          format = "📁 [$path]($style)[$read_only]($read_only_style) ";
          style = "bold cyan";
          read_only = "🔒";
          truncation_length = 3;
          truncate_to_repo = true;
        };

        # Git with emojis
        git_branch = {
          symbol = "🌱 ";
          format = "[$symbol$branch]($style) ";
          style = "bold purple";
        };

        git_status = {
          format = "([\\[$all_status$ahead_behind\\]]($style) )";
          style = "bold red";
          conflicted = "🏳";
          up_to_date = "✓";
          untracked = "🤷";
          ahead = "⇡\${count}";
          diverged = "⇕⇡\${ahead_count}⇣\${behind_count}";
          behind = "⇣\${count}";
          stashed = "📦";
          modified = "📝";
          staged = "[++\\(\${count}\\)](green)";
          renamed = "👅";
          deleted = "🗑";
        };

        # Language/tool symbols with emojis
        aws = {
          symbol = "☁️ ";
          format = "[$symbol($profile)(\\($region\\))]($style) ";
        };
        
        gcloud = {
          format = "[$symbol$active(\\($region\\))]($style) ";
          symbol = "🅶 ";
        };

        docker_context = {
          symbol = "🐳 ";
        };

        nodejs = {
          symbol = "⬢ ";
        };

        python = {
          symbol = "🐍 ";
        };

        rust = {
          symbol = "🦀 ";
        };

        java = {
          symbol = "☕ ";
        };

        golang = {
          symbol = "🐹 ";
        };

        # Custom three-line format:
        # Line 1: username@hostname + time
        # Line 2: directory + git info + language/tool info  
        # Line 3: prompt character
        format = "$username$hostname$time$line_break$directory$git_branch$git_status$nodejs$python$rust$java$golang$docker_context$aws$gcloud$line_break$character";

        palette = "catppuccin_mocha";
      }
      // (
        # Try to load catppuccin theme, fall back to empty config if not available for this system
        if nur-ryan4yin.packages ? ${pkgs.system} && nur-ryan4yin.packages.${pkgs.system} ? catppuccin-starship
        then builtins.fromTOML (builtins.readFile "${nur-ryan4yin.packages.${pkgs.system}.catppuccin-starship}/palettes/mocha.toml")
        else {}
      );
  };
}
