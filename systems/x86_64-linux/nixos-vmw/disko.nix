{
  lib,
  namespace,
  config,
  ...
}: let
  inherit (lib) recursiveUpdate;
  mkPartlabel = d: p: "/dev/disk/by-partlabel/disk-${d}-${p}";
  homePath = config.snowfallorg.users.${namespace}.home.path;

  settings = {
    disk = {
      main.device = "/dev/disk/by-id/nvme-VMware_Virtual_NVMe_Disk_VMware_NVME_0000_1";
      ssd.device = "/dev/disk/by-id/nvme-VMware_Virtual_NVMe_Disk_VMware_NVME_0000_2";
      hdd.device = "/dev/disk/by-id/nvme-VMware_Virtual_NVMe_Disk_VMware_NVME_0000_3";
    };
    zpool.tank = {
      rootFsOptions = {
        atime = "off";
        special_small_blocks = "64k";
      };
      datasets = {
        "${namespace}/home" = {
          type = "zfs_fs";
          options.mountpoint = homePath;
        };
      };
    };
  };
in {
  disko.devices = recursiveUpdate settings {
    disk = {
      main = {
        type = "disk";
        content = {
          type = "gpt";
          partitions = {
            ESP = {
              type = "EF00";
              size = "1G";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/efi";
                mountOptions = ["umask=0077"];
              };
            };
            root = {
              end = "-8G"; # (100%)-8G
              content = {
                type = "btrfs";
                subvolumes = {
                  "@" = {
                    mountOptions = ["compress=zstd"];
                    mountpoint = "/";
                  };
                  "@home" = {
                    mountOptions = ["compress=zstd"];
                    mountpoint = "/home";
                  };
                  "@nix" = {
                    mountOptions = ["compress=zstd" "noatime"];
                    mountpoint = "/nix";
                  };
                };
              };
            };
            zramSwap.size = "100%"; # 100%-(8G)
          };
        };
      };
      ssd = {
        type = "disk";
        content = {
          type = "gpt";
          partitions = {
            zspecial = {
              end = "-16G"; # (100%)-8G
              content = {
                type = "zfs";
                pool = "tank";
              };
            };
            zlog = {
              size = "100%"; # 100%-(16G)
              content = {
                type = "zfs";
                pool = "tank";
              };
            };
          };
        };
      };
      hdd = {
        type = "disk";
        content = {
          type = "gpt";
          partitions = {
            zfs = {
              size = "100%";
              content = {
                type = "zfs";
                pool = "tank";
              };
            };
          };
        };
      };
    };
    zpool.tank = {
      type = "zpool";
      mode = {
        topology = {
          type = "topology";
          vdev = [
            {
              members = ["hdd"];
            }
          ];
          log = [
            {
              members = [(mkPartlabel "ssd" "zlog")];
            }
          ];
          special = [
            {
              members = [(mkPartlabel "ssd" "zspecial")];
            }
          ];
        };
      };
    };
  };
}
