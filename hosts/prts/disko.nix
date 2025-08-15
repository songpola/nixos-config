{
  delib,
  config,
  inputs,
  ...
}:
let
  /*
    DISK = main

    LAYOUT:
    |<-  ESP (1G)  ->||<- root (100%) ->||<- zramSwap (8G) ->|
    |0             1G||              -8G||               100%|
    |(start)    (end)||            (end)||              (end)|
  */

  disk.main = {
    type = "disk";
    device = "/dev/disk/by-id/nvme-WDS250G3X0C-00SJG0_191679805165_1";
    content = {
      type = "gpt";
      inherit partitions;
    };
  };

  partitions.ESP = {
    type = "EF00";
    start = "0";
    end = "1G";
    content = {
      type = "filesystem";
      format = "vfat";
      mountpoint = "/efi";
      mountOptions = [ "umask=0077" ];
    };
  };

  partitions.root = {
    end = "-8G";
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

  partitions.zramSwap = {
    end = "100%";
  };
in
delib.host {
  name = "prts";

  nixos = {
    imports = [ inputs.disko.nixosModules.default ];

    zramSwap = {
      enable = true;
      writebackDevice = config.disko.devices.disk.main.content.partitions.zramSwap.device;
    };

    disko.devices = { inherit disk; };
  };
}
