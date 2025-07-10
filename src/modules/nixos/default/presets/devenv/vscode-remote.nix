{
  lib,
  config,
  namespace,
  pkgs,
  ...
}:
lib.${namespace}.mkPresetModule config [ "devenv" "vscode-remote" ] {
  # Setup VSCode Remote
  environment.systemPackages = [ pkgs.wget ];
  programs.nix-ld.enable = true;
}
