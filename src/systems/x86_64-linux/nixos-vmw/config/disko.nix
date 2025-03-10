let
  mkPartlabel = d: p: "/dev/disk/by-partlabel/disk-${d}-${p}";
in {
  devices = {
    disk = {
      main = {
        device = "/dev/disk/by-id/nvme-VMware_Virtual_NVMe_Disk_VMware_NVME_0000_1";
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
        device = "/dev/disk/by-id/nvme-VMware_Virtual_NVMe_Disk_VMware_NVME_0000_2";
        type = "disk";
        content = {
          type = "gpt";
          partitions = {
            zspecial = {
              end = "-16G";
              content = {
                type = "zfs";
                pool = "tank";
              };
            };
            zlog = {
              size = "100%";
              content = {
                type = "zfs";
                pool = "tank";
              };
            };
          };
        };
      };
      hdd = {
        device = "/dev/disk/by-id/nvme-VMware_Virtual_NVMe_Disk_VMware_NVME_0000_3";
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
    zpool = {
      tank = {
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
        options = {
          ashift = "12";
        };
        rootFsOptions = {
          special_small_blocks = "64k";
        };
        # mountpoint = "/mnt/tank";
      };
    };
  };
}
