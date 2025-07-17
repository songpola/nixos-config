{
  lib,
  config,
  namespace,
  pkgs,
  ...
}:
let
  inherit (lib.${namespace}) mkIfBaseEnabled;
in
lib.${namespace}.mkPresetModule config [ "podman" ] {
  systemConfig = [
    {
      virtualisation.podman.enable = true;

      environment.systemPackages = [ pkgs.podman-tui ];
    }
  ];
  extraConfig = [
    (mkIfBaseEnabled config "server" {
      systemConfig = [
        {
          users.users.${namespace} = {
            linger = true; # required for auto start before user login
            autoSubUidGidRange = true; # required for rootless container with multiple users
          };
        }
      ];
    })
  ];
}
