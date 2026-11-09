# Podman Quadlet units from Nix (quadlet-nix): one systemd unit per container, network,
# volume or pod, under `virtualisation.quadlet`. quadlet-nix writes each unit to
# /etc/containers/systemd/<name>.<kind> but doesn't own the directory, so hand-written
# quadlets (or `podman quadlet install`) can live next to them.
#
# Unit names: `<name>.service` for containers, `<name>-network.service` for networks,
# `<name>-volume.service` for volumes. Reference other quadlets with `.ref`
# (e.g. `networks = [ config.virtualisation.quadlet.networks.caddy.ref ]`): Quadlet then
# resolves the name and adds the systemd dependencies.
#
# Auto-update: label containers with `programs.podman`'s `meta.autoUpdateLabels`; the timer
# comes from its `auto-update` sub-aspect. Leave quadlet-nix's `autoUpdate.enable` off: it
# replaces the timer's schedule.
{
  den,
  inputs,
  lib,
  ...
}:
{
  flake-file.inputs.quadlet-nix.url = "github:SEIAROTg/quadlet-nix";

  den.aspects.programs.quadlet = {
    includes = [ den.aspects.programs.podman ];

    nixos =
      { config, ... }:
      {
        imports = [ inputs.quadlet-nix.nixosModules.quadlet ];

        virtualisation.quadlet.enable = true;

        # Container data may live on ZFS datasets, mounted by zfs-mount.service without mount
        # units (see programs.podman). Ordered only, as there.
        systemd.services = lib.mkIf config.boot.zfs.enabled (
          lib.mapAttrs (_: _: { after = [ "zfs-mount.service" ]; }) config.virtualisation.quadlet.containers
        );
      };
  };
}
