{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    cowsay
  ];
}
