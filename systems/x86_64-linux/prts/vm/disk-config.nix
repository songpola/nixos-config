{
  disko.devices = {
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
              end = "-8G";
              content = {
                type = "btrfs";
                extraArgs = ["-f"]; # Override existing partition
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
        # ssd = {
        #   device = "/dev/disk/by-id/ata-VMware_Virtual_SATA_Hard_Drive_00000000000000000001";
        #   type = "disk";
        #   content = {
        #     type = "gpt";
        #     partitions = {
        #       zfs = {
        #         size = "100%";
        #         content = {
        #           type = "zfs";
        #           pool = "tank";
        #         };
        #       };
        #     };
        #   };
        # };
        # hdd = {
        #   device = "/dev/disk/by-id/ata-VMware_Virtual_SATA_Hard_Drive_02000000000000000001";
        #   type = "disk";
        #   content = {
        #     type = "gpt";
        #     partitions = {
        #       zfs = {
        #         size = "100%";
        #         content = {
        #           type = "zfs";
        #           pool = "tank";
        #         };
        #       };
        #     };
        #   };
        # };
      };
    };
    # zpool = {
    #   tank = {
    #     type = "zpool";
    #     mode = {
    #       topology = {
    #         type = "topology";
    #         vdev = [
    #           {
    #             members = ["hdd"];
    #           }
    #         ];
    #         special = [
    #           {
    #             members = ["ssd"];
    #           }
    #         ];
    #       };
    #     };
    #   };
    # };
  };
}
