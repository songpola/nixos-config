{
  disko.devices = {
    disk = {
      main = {
        device = "/dev/disk/by-id/nvme-eui.a6357f416ba205d6000c2969d8c46525";
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
              end = "-8G";
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
            swap.size = "100%"; # zramSwap backing device
          };
        };
        ssd = {
          device = "/dev/disk/by-id/wwn-0x5000c29cc95f4c89";
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
          device = "/dev/disk/by-id/wwn-0x5000c29343f3840c";
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
            special = [
              {
                members = ["ssd"];
              }
            ];
          };
        };
        rootFsOptions = {
          compression = "zstd";
          "com.sun:auto-snapshot" = "false";
        };
        mountpoint = "/";
        datasets = {
          # See examples/zfs.nix for more comprehensive usage.
          zfs_fs = {
            type = "zfs_fs";
            mountpoint = "/zfs_fs";
            options."com.sun:auto-snapshot" = "true";
          };
        };
      };
    };
  };
}
