{
  lib,
  config,
  namespace,
  pkgs,
  ...
}:
lib.${namespace}.mkPresetModule config [ "devenv" "node" ] {
  systemConfig = [
    {
      # Node.js Development Environment
      environment.systemPackages = with pkgs; [
        nodejs
        corepack
        bun
      ];
    }
  ];
}
