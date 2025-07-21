{
  lib,
  config,
  namespace,
  pkgs,
  ...
}:
let
  inherit (lib.${namespace}) mkIfBaseEnabled sshPublicKeys;
in
lib.${namespace}.mkPresetModule config [ "podman" ] {
  systemConfig = [
    {
      virtualisation.podman.enable = true;

      environment.systemPackages = [ pkgs.podman-tui ];

      users.users.${namespace} = {
        # Required for auto start before user login
        # and prevent containers termination on shell logout
        linger = true;

        # Required for rootless container with multiple users
        # NOTE: Already defaults to true if no subUidRanges and subGidRanges are set
        # autoSubUidGidRange = true;
      };
    }
  ];
  extraConfig = [
    (mkIfBaseEnabled config "wsl" {
      systemConfig = [
        {
          # https://podman-desktop.io/docs/podman/accessing-podman-from-another-wsl-instance
          users.groups = {
            # For podman-machine-default-root connection
            podman-machine-root = {
              gid = 10;
              members = [ namespace ];
            };
            # For podman-machine-default connection
            podman-machine-user = {
              gid = 1000;
              members = [ namespace ];
            };
          };
        }
      ];
    })
  ];
}
