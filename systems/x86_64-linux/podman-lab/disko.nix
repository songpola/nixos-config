{lib, ...}: let
  inherit (lib) recursiveUpdate;

  settings = {
    disk = {
      main.device = "/dev/vda";
      tank.device = "/dev/vdb";
    };
    zpool.tank = {
      rootFsOptions = {
        atime = "off";
        xattr = "sa";
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
              end = "-4G"; # (100%)-8G
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
      tank = {
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
              members = ["tank"];
            }
          ];
        };
      };
    };
  };
}
