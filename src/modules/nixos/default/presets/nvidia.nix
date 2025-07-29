{
  lib,
  config,
  namespace,
  ...
}:
lib.${namespace}.mkPresetModule config [ "nvidia" ] {
  systemConfig = [
    {
      services.xserver.videoDrivers = [ "nvidia" ];
    }
  ];
}
