{
  disko.devices = {
    disk = {
      main = {
        device = "/dev/disk/by-id/nvme-WDS250G3X0C-00SJG0_191679805165_1";
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
            zramSwap.size="100%"; # 100%-(8G)
          };
        };
      };
    };
  };
}
