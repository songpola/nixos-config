{ config, namespace, ... }:
{
  imports = [
    ./disko.nix
    ./network.nix
    ./nvidia.nix
  ];

  facter.reportPath = ./facter.json;

  ${namespace} = {
    stateVersions = {
      system = "24.11";
      home = "24.11";
    };
    base = "server";
    presets = {
      stdenv = true;
      tailscale = true;
      zfs = true;
    };
    homePresets = {
      git = true;
      shells = true;
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

  services.tailscale.extraSetFlags = [
    "--advertise-routes=10.0.0.0/16"
    "--advertise-exit-node"
  ];
}
