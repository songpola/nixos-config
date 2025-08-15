{
  delib,
  host,
  ...
}:
delib.module {
  name = "zfs";

  options =
    with delib;
    enableOptionWith host.zfsFeatured {
      # Can be generated with:
      # `head -c 8 /etc/machine-id` (from machine-id)
      # or
      # `head -c 4 /dev/urandom | od -A n -t x4` (random)
      hostId = noDefault (strOption null);

      pools = listOfOption str [ "tank" ];
    };

  nixos.ifEnabled =
    { cfg, ... }:
    {
      networking.hostId = cfg.hostId;

      boot = {
        supportedFilesystems = [ "zfs" ];
        zfs = {
          devNodes = "/dev/disk/by-partlabel";
          forceImportRoot = false;
          extraPools = cfg.pools;
        };
      };
      services.zfs = {
        autoScrub.enable = true;
        trim.enable = true;
      };
    };
}
