{ lib, ... }:
{
  den.aspects.programs.podman = {
    nixos =
      { config, pkgs, ... }:
      {
        virtualisation.podman.enable = true;

        # Containers on user-created networks resolve names through aardvark-dns on the
        # bridge gateway, which the host firewall drops (nixpkgs only opens it for the default
        # network). Allow DNS from every podman bridge (podman0, podman1, ...).
        networking.firewall.extraInputRules = lib.mkIf config.networking.nftables.enable ''
          iifname "podman*" meta l4proto { tcp, udp } th dport 53 accept comment "podman aardvark-dns"
        '';
        networking.firewall.extraCommands = lib.mkIf (!config.networking.nftables.enable) ''
          iptables -A nixos-fw -i podman+ -p udp --dport 53 -j nixos-fw-accept
          iptables -A nixos-fw -i podman+ -p tcp --dport 53 -j nixos-fw-accept
        '';

        # Use original implementation for `podman compose` commands
        environment.systemPackages = [ pkgs.docker-compose ];
        virtualisation.containers.containersConf.settings.engine.compose_warning_logs = false;

        # Start containers with a restart policy (e.g. `unless-stopped`) on boot.
        # The unit ships with podman but is not enabled by default.
        systemd.services.podman-restart.wantedBy = [ "multi-user.target" ];
      };

    user.extraGroups = [ "podman" ];

    # Enable lingering for auto-starting containers before user login
    # and prevent containers termination on shell logout.
    # NOTE: Lingering did not work well on WSL (v3); untested since.
    # _.user-linger.user.linger = true;

    # Labels that opt a container into the `auto-update` sub-aspect's updates, and keep other
    # updaters away: Dockhand (services.dockhand) would recreate it outside its systemd unit.
    meta.autoUpdateLabels = {
      "io.containers.autoupdate" = "registry";
      "dockhand.update" = "false";
    };

    # Daily `podman auto-update` (the timer ships with podman): pulls newer images for containers
    # labelled with `meta.autoUpdateLabels` and restarts their systemd unit, rolling back to the old
    # image if the unit fails to start. Only for containers in a systemd unit (PODMAN_SYSTEMD_UNIT,
    # set by podman, e.g. oci-containers) with a fully qualified image name.
    # What "started" means is the unit's readiness (oci-containers `podman.sdnotify`): `conmon`
    # (default) only catches an image that can't start; `container` waits for the app's own
    # sd_notify, `healthy` for its health check, so they also catch one that starts but isn't ready.
    _.auto-update.nixos.systemd.timers.podman-auto-update.wantedBy = [ "timers.target" ];

    # Keeps named volumes (which are real data) apart from images and layers in the
    # graph root, e.g. on a dataset with snapshots and scrubs.
    _.volume-path = {
      settings.path = lib.mkOption {
        type = lib.types.str;
        description = "Directory for podman named volumes, e.g. /tank/v2/podman-volumes";
      };

      nixos =
        { host, ... }:
        {
          virtualisation.containers.containersConf.settings.engine.volume_path =
            host.settings.programs.podman.volume-path.path;
        };
    };

    # Don't use: slow (podman lists every layer dataset on each command),
    # use the default overlay driver; kept here for reference.
    # _.zfs-storage-driver = {
    #   settings.dataset = lib.mkOption {
    #     type = lib.types.str;
    #     description = "ZFS dataset used by podman's storage driver, e.g. tank/unmanaged/podman";
    #   };

    #   nixos =
    #     { host, ... }:
    #     {
    #       virtualisation.containers.storage.settings.storage = {
    #         driver = "zfs";
    #         options.zfs.fsname = host.settings.programs.podman.zfs-storage-driver.dataset;
    #       };
    #     };
    # };
  };
}
