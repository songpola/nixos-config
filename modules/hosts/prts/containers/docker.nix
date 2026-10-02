# Docker (rootful), as an alternative to podman.
# DISABLED: to enable, add `den.aspects."prts".docker` to `den.aspects."prts".includes`.
{
  den.aspects."prts"._.docker = {
    nixos = {
      virtualisation.docker.enable = true;

      # The `tank/docker` dataset is mounted on `/var/lib/docker`
      virtualisation.docker.storageDriver = "zfs";

      users.users."songpola" = {
        extraGroups = [ "docker" ];
        # Enable lingering for auto-starting containers before user login
        # and prevent containers termination on shell logout.
        linger = true;
      };
    };
  };
}
