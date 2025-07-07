{ pkgs, ... }:
{
  # Setup VSCode Remote
  environment.systemPackages = [ pkgs.wget ];
  programs.nix-ld.enable = true;
}
