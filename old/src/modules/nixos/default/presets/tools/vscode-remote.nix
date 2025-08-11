{
  lib,
  config,
  namespace,
  pkgs,
  ...
}:
lib.${namespace}.mkPresetModule config [ "tools" "vscode-remote" ] {
  systemConfig = [
    {
      # Setup VSCode Remote
      environment.systemPackages = [ pkgs.wget ];
      programs.nix-ld.enable = true;
    }
  ];
}
