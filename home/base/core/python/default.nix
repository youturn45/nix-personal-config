{ pkgs, ... }:
let
  python = pkgs.python311;
in
{
  home.packages = with pkgs; [
    python
    python.pkgs.pip
    pyright # python language server
  ];

  programs.zsh.shellAliases = {
    devshell = ''
      if [ ! -d .venv ]; then
        ${python}/bin/python3 -m venv .venv
        .venv/bin/pip install -r requirements.txt
      fi
      source .venv/bin/activate
      $SHELL
    '';
  };
}