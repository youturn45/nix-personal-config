# Projection of actual evaluated configuration; never a partial Nix renderer.
c: let
  user = c.system.primaryUser;
  home = c.home-manager.users.${user};
  names = map (p: p.name or "") (c.environment.systemPackages ++ home.home.packages);
  management = builtins.filter (n: builtins.match "(mihomo-(sync|reload|icloud-sync)|sync_clash)" n != null) names;
in {
  username = user;
  activation = c.system.activationScripts.script.text;
  autoLoginUser = c.system.defaults.loginwindow.autoLoginUser;
  mihomo_sync = (builtins.head (builtins.filter (p: (p.name or "") == "mihomo-sync") c.environment.systemPackages)).text;
  management_commands = builtins.concatStringsSep "\n" management;
  npm_setup = home.home.activation.setupNpm.data;
  git_activation = home.home.activation.removeExistingGitconfig.data;
  claude_settings_activation = home.home.activation.claudeSettings.data;
  claude_runtime_activation = home.home.activation.claudeRuntimeConfig.data;
  codex_activation = home.home.activation.codexMergeConfig.data;
  shell_init = home.programs.zsh.initContent;
  shell_proxy_default = home.youturn.proxy.default;
  mihomo_daemon = builtins.elemAt c.launchd.daemons.mihomo.serviceConfig.ProgramArguments 2;
  npm_install_present =
    if home.home.activation ? installNpm
    then "yes"
    else "no";
}
