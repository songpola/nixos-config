{ den, ... }:
{
  den.hosts."x86_64-linux"."prts" = {
    users."songpola" = { };
    zfs = {
      enable = true;
      hostId = "eb8b6756";
      extraPools = [ "tank" ];
    };
    nvidia = {
      enable = true;
      # GTX 1050 Ti does not support open-source kernel module
      open = false;
      # The 590+ drivers dropped Pascal (GTX 10 series)
      driverBranch = "legacy_580";
    };

    settings = {
      programs.getty.autologinUser = "songpola";

      networking.networkd-bridge.macAddress = "b4:2e:99:91:b1:10"; # eno1

      programs.podman.zfs-storage-driver.dataset = "tank/unmanaged/podman";

      services.tailscale = {
        optimizeUdpInterface = "eno1";
        openFirewall = true;
        operator = "songpola";
        ssh = true;
        advertiseRoutes = [ "10.0.0.0/16" ];
        advertiseExitNode = true;
      };
    };
  };

  den.aspects."prts" = {
    includes = with den.aspects; [
      profiles.base
      profiles.server

      security.passwordless-wheel

      networking.networkd-bridge

      programs.podman
      programs.podman.zfs-storage-driver
      # programs.sops

      services.tailscale
      services.auto-upgrade
      services.auto-upgrade.allow-reboot
    ];

    nixos = {
      system.stateVersion = "24.11";

      # Hardware configs
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
          efiSysMountPoint = "/efi";
        };
      };
    };

    homeManager.home.stateVersion = "24.11";
  };
}
