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
      };

    user.extraGroups = [ "podman" ];

    # Enable lingering for auto-starting containers before user login
    # and prevent containers termination on shell logout.
    # NOTE: Lingering did not work well on WSL (v3); untested since.
    # _.user-linger.user.linger = true;

    _.zfs-storage-driver = {
      settings.dataset = lib.mkOption {
        type = lib.types.str;
        description = "ZFS dataset used by podman's storage driver, e.g. tank/unmanaged/podman";
      };

      nixos =
        { host, ... }:
        {
          virtualisation.containers.storage.settings.storage = {
            driver = "zfs";
            options.zfs.fsname = host.settings.programs.podman.zfs-storage-driver.dataset;
          };
        };
    };
  };
}
