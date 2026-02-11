{pkgs, ...}: {
  programs.starship = {
    enable = true;

    enableBashIntegration = true;
    enableZshIntegration = true;
    enableNushellIntegration = true;

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

      git_branch = {
        symbol = " ";
        format = "[$symbol$branch]($style) ";
        style = "bold purple";
      };

      git_status = {
        format = "([\\[$all_status$ahead_behind\\]]($style) )";
        style = "bold red";
        conflicted = "=";
        up_to_date = "✓";
        untracked = "?";
        ahead = "⇡\${count}";
        diverged = "⇕⇡\${ahead_count}⇣\${behind_count}";
        behind = "⇣\${count}";
        stashed = "*";
        modified = "!";
        staged = "[+\\(\${count}\\)](green)";
        renamed = "»";
        deleted = "✘";
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

      palettes.catppuccin_mocha = {
        rosewater = "#f5e0dc";
        flamingo = "#f2cdcd";
        pink = "#f5c2e7";
        mauve = "#cba6f7";
        red = "#f38ba8";
        maroon = "#eba0ac";
        peach = "#fab387";
        yellow = "#f9e2af";
        green = "#a6e3a1";
        teal = "#94e2d5";
        sky = "#89dceb";
        sapphire = "#74c7ec";
        blue = "#89b4fa";
        lavender = "#b4befe";
        text = "#cdd6f4";
        subtext1 = "#bac2de";
        subtext0 = "#a6adc8";
        overlay2 = "#9399b2";
        overlay1 = "#7f849c";
        overlay0 = "#6c7086";
        surface2 = "#585b70";
        surface1 = "#45475a";
        surface0 = "#313244";
        base = "#1e1e2e";
        mantle = "#181825";
        crust = "#11111b";
      };
    };
  };
}
