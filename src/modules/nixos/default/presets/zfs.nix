{
  lib,
  config,
  namespace,
  ...
}:
lib.${namespace}.mkPresetModule2 config [ "zfs" ] {
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
