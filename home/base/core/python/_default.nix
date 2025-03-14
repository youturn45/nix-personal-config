{ pkgs, ... }:
 let
   python = pkgs.python311;
 in
 {
   home.packages = with pkgs; [
     python
     #python.pkgs.pip
     #pyright # python language server
   ];
 
   programs.zsh.shellAliases = {
   };
 }