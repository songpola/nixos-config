{
  lib,
  config,
  namespace,
  pkgs,
  ...
}:
lib.${namespace}.mkPresetModule config [ "tools" "sysadmin" ] {
  systemConfig = [
    {
      environment.systemPackages = with pkgs; [
        lsof # List open files
        doggo # DNS lookup
      ];
    }
  ];
}
