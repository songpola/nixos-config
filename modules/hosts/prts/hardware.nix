# prts hardware: facter report, GPU, ZFS pool, swap and bootloader (disk layout is in disks.nix).
{
  den.hosts."x86_64-linux"."prts".settings = {
    zfs = {
      hostId = "eb8b6756";
      extraPools = [ "tank" ];
    };

    nvidia = {
      # GTX 1050 Ti does not support open-source kernel module
      open = false;
      # The 590+ drivers dropped Pascal (GTX 10 series)
      driverBranch = "legacy_580";
    };
  };

  den.aspects."prts".nixos =
    { config, ... }:
    {
      hardware.facter.reportPath = ./facter.json;

      # Use ZRAM as swap (no swap partition)
      zramSwap.enable = true;

      # GRUB EFI Bootloader
      boot.loader = {
        grub = {
          device = "nodev";
          efiSupport = true;
        };
        efi = {
          canTouchEfiVariables = true;
          # The ESP's mount point, from disks.nix
          efiSysMountPoint = config.disko.devices.disk."main".content.partitions."ESP".content.mountpoint;
        };
      };
    };
}
