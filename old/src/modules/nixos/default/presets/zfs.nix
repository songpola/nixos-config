{
  lib,
  config,
  namespace,
  ...
}:
lib.${namespace}.mkPresetModule config [ "zfs" ] {
  systemConfig = [
    {
      boot = {
        supportedFilesystems = [ "zfs" ];
        zfs = {
          devNodes = "/dev/disk/by-partlabel";
          forceImportRoot = false;
          extraPools = [ "tank" ];
        };
      };
      services.zfs = {
        autoScrub.enable = true;
        trim.enable = true;
      };
    }
  ];
}
