{
  lib,
  config,
  namespace,
  ...
}:
lib.${namespace}.mkPresetModule config [ "podman" ] {
  systemConfig = [
    {
      virtualisation.podman.enable = true;
    }
  ];
}
