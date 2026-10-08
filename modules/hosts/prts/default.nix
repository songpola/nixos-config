{ den, ... }:
{
  den.hosts."x86_64-linux"."prts" = {
    users."songpola" = { };
    zfs.enable = true;
    nvidia.enable = true;

    settings = {
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

      networking.networkd-bridge.macAddress = "b4:2e:99:91:b1:10"; # eno1

      programs.getty.autologinUser = "songpola";

      programs.podman.volume-path.path = "/tank/v2/podman-volumes";

      services.tailscale = {
        optimizeUdpInterface = "eno1";
        openFirewall = true;
        operator = "songpola";
        ssh = true;
        advertiseRoutes = [ "10.0.0.0/16" ];
        advertiseExitNode = true;
      };

      security.acme-cloudflare = {
        email = "songpola@songpola.dev";
        sopsFile = ./secrets/cloudflare.secrets.yaml;
      };

      services.caddy-reverse-proxy.configDir = "/tank/v2/services/caddy-reverse-proxy/config";

      services.kanidm = {
        # Upgrade one release at a time, see the option's description
        version = "1_11";
        domain = "idm.songpola.dev";
        backupDir = "/tank/v2/services/kanidm/backups";
      };

      services.dockhand = {
        dataDir = "/tank/v2/services/dockhand";
        user = "songpola";
        domain = "dockhand.songpola.dev";
      };

      services.dozzle = {
        enableActions = true;
        domain = "dozzle.songpola.dev";
      };
    };
  };

  den.aspects."prts" = {
    includes = with den.aspects; [
      profiles.base
      profiles.server

      networking.networkd-bridge

      security.passwordless-wheel

      programs.podman
      programs.podman.volume-path
      programs.sops

      services.auto-upgrade
      services.auto-upgrade.allow-reboot
      services.tailscale

      services.caddy-reverse-proxy
      services.kanidm
      services.dockhand
      services.dozzle
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
