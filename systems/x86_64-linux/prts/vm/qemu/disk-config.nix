{
  disko.devices = {
    disk = {
      main = {
        device = "/dev/disk/by-id/ata-QEMU_HARDDISK_QM00001";
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
              end = "-8G"; # (100%)-4G-4G
              content = {
                type = "btrfs";
                # extraArgs = ["-f"]; # Override existing partition
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
            # zramSwap backing device
            swap = {
              end = "-4G"; # 100%-(4G)-4G
            };
            zfs = {
              size = "100%"; # 100%-4G-(4G)
              content = {
                type = "zfs";
                pool = "tank";
              };
            };
          };
        };
      };
      ssd = {
        device = "/dev/disk/by-id/ata-QEMU_HARDDISK_QM00003";
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
      hdd = {
        device = "/dev/disk/by-id/ata-QEMU_HARDDISK_QM00005";
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
                members = ["main"];
              }
            ];
            special = [
              {
                members = ["ssd"];
              }
            ];
          };
        };
        # rootFsOptions = {
        #   compression = "zstd";
        #   # "com.sun:auto-snapshot" = "false";
        # };
        # mountpoint = "/mnt/tank";
        # datasets = {
        #   # See examples/zfs.nix for more comprehensive usage.
        #   test = {
        #     type = "zfs_fs";
        #     mountpoint = "/mnt/tank/test";
        #     # options."com.sun:auto-snapshot" = "true";
        #   };
        # };
      };
    };
  };
}
