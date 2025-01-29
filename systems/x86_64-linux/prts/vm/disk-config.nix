{
  networking.hostId = "b4a16b88";
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
      };
      ssd = {
        device = "/dev/disk/by-id/wwn-0x5000c29cc95f4c89";
        type = "disk";
        content = {
          type = "gpt";
          partitions = {
            zslog = {
              size = "16G";
              content = {
                type = "zfs";
                pool = "tank";
              };
            };
            zspecial = {
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
            zdata = {
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
                members = ["/dev/disk/by-partlabel/disk-hdd-zdata"];
              }
            ];
            log = [
              {
                members = ["/dev/disk/by-partlabel/disk-ssd-zslog"];
              }
            ];
            special = [
              {
                members = ["/dev/disk/by-partlabel/disk-ssd-zspecial"];
              }
            ];
          };
        };
        rootFsOptions = {
          compression = "zstd";
          # "com.sun:auto-snapshot" = "false";
        };
        mountpoint = "/mnt/tank";
        datasets = {
          # See examples/zfs.nix for more comprehensive usage.
          test = {
            type = "zfs_fs";
            mountpoint = "/mnt/tank/test";
            # options."com.sun:auto-snapshot" = "true";
          };
        };
      };
    };
  };
}
