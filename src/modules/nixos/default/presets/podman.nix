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
          # Enable SSH access for Podman Desktop
          ${namespace}.presets = {
            services = {
              sshd = true;
            };
          };

          # On Windows, using Podman Desktop:
          # `podman system connection add --identity C:\Users\songpola\.ssh\podman-desktop-nixos-wsl nixos-wsl songpola@localhost`
          # and set it as default connection:
          # `podman system connection default nixos-wsl`
          users.users.${namespace}.openssh.authorizedKeys.keys = [
            sshPublicKeys.podman-desktop-nixos-wsl
          ];
        }
      ];
    })
  ];
}
