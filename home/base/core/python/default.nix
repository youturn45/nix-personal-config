{ pkgs, ... }:
 let
   pyver = "312";
 in
 {
   home.packages = with pkgs; [
    python312
    python312Packages.pip
    python312Packages.virtualenvwrapper
    python312Packages.Kaggle
     #python.pkgs.pip
     #pyright # python language server
   ];
 
   programs.zsh.shellAliases = {
   };
 }