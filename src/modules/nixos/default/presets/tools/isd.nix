{
  lib,
  config,
  namespace,
  pkgs,
  ...
}:
lib.${namespace}.mkPresetModule config [ "tools" "isd" ] {
  systemConfig = [
    {
      # isd – interactive systemd
      environment.systemPackages = [ pkgs.isd ];
    }
  ];
}
