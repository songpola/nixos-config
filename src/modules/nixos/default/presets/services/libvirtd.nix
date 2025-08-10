{
  lib,
  config,
  namespace,
  ...
}:
lib.${namespace}.mkPresetModule config [ "services" "libvirtd" ] {
  systemConfig = [
    {
      virtualisation.libvirtd.enable = true;

      users.users.${namespace}.extraGroups = [ "libvirtd" ];
    }
  ];
}
