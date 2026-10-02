{ den, ... }:
{
  den.aspects."prts" = {
    includes = [ den.aspects.programs.disko ];

    # WD Black SN750 250GB (WDS250G3X0C), no heatsink
    # M.2 2280, PCIe 3.0 x4 NVMe, 64-layer 3D NAND
    # Seq. read up to 3,100 MB/s, seq. write up to 1,600 MB/s
    # Random read 220K IOPS, random write 180K IOPS
    # Endurance 200 TBW, 5-year warranty
    nixos.disko.devices.disk."main" = {
      type = "disk";
      device = "/dev/disk/by-id/nvme-WDS250G3X0C-00SJG0_191679805165_1";
      content = {
        type = "gpt";
        partitions = {
          "ESP" = {
            type = "EF00";
            size = "1G";
            content = {
              type = "filesystem";
              format = "vfat";
              mountpoint = "/efi";
              mountOptions = [ "umask=0077" ];
            };
          };
          "root" = {
            size = "100%";
            content = {
              type = "btrfs";
              subvolumes = {
                "@" = {
                  mountOptions = [ "compress=zstd" ];
                  mountpoint = "/";
                };
                "@nix" = {
                  mountOptions = [
                    "compress=zstd"
                    "noatime"
                  ];
                  mountpoint = "/nix";
                };
                "@home" = {
                  mountOptions = [ "compress=zstd" ];
                  mountpoint = "/home";
                };
              };
            };
          };
        };
      };
    };
  };
}
