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
              end = "-24G"; # (100%)-16G-8G
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
            # zramSwap backing device
            swap = {
              end = "-8G"; # 100%-(16G)-8G
            };
            zfs = {
              size = "100%"; # 100%-16G-(8G)
              content = {
                type = "zfs";
                pool = "tank";
              };
            };
          };
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
      };
    };
  };
}
