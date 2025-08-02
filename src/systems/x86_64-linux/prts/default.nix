{ config, namespace, ... }:
{
  imports = [
    ./disko.nix
    ./network.nix
    ./containers/caddy.nix
    ./containers/adguardhome.nix
    ./containers/dozzle.nix
    ./containers/trilium.nix
    ./containers/radicale.nix
    ./containers/int-301-db.nix
  ];

  facter.reportPath = ./facter.json;

  ${namespace} = {
    stateVersions = {
      system = "24.11";
      home = "24.11";
    };
    base = "server";
    presets = {
      stdenv.full = true;

      zfs = true;
      nvidia = true;

      services = {
        podman = true;
        tailscale = true;
      };

      binary-cache.server = true;
    };
  };

  # For ZFS
  # Can be generated with:
  # `head -c 8 /etc/machine-id` (from machine-id)
  # or
  # `head -c 4 /dev/urandom | od -A n -t x4` (random)
  networking.hostId = "eb8b6756";

  zramSwap = {
    enable = true;
    writebackDevice = config.disko.devices.disk.main.content.partitions.zramSwap.device;
  };

  # 1050Ti (Pascal) doesn't support open-source kernel module
  hardware.nvidia.open = false;

  services.tailscale.extraSetFlags = [
    "--advertise-routes=10.0.0.0/16"
    "--advertise-exit-node"
  ];

  # I don't want to type my password every time I use sudo on this system
  security.sudo.wheelNeedsPassword = false;
}
