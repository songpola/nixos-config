{ lib, ... }:
{
  den.aspects.programs.podman = {
    nixos =
      { pkgs, ... }:
      {
        virtualisation.podman.enable = true;

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
