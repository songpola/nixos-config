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
lib.${namespace}.mkPresetModule config [ "services" "podman" ] {
  systemConfig = [
    {
      virtualisation.podman.enable = true;

      environment.systemPackages = with pkgs; [
        podman-tui
        docker-compose # use original implementation for `podman compose` commands
      ];

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
        # Remote: NixOS-WSL -> Podman Desktop
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
        # Remote: Podman Desktop -> NixOS-WSL
        {
          # Enable SSH access for Podman Desktop
          services.openssh = {
            enable = true;
            # Windows has built-in SSH server, so we use a different port
            ports = [ 2222 ];
          };
          users.users.${namespace}.openssh.authorizedKeys.keys = [
            sshPublicKeys.podman-desktop-nixos-wsl
          ];
        }
      ];
    })
  ];
}
