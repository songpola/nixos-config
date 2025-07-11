{
  lib,
  config,
  namespace,
  ...
}:
lib.${namespace}.mkPresetModule config [ "bootable" ] {
  boot.loader = {
    grub = {
      device = "nodev";
      efiSupport = true;
    };
    efi = {
      canTouchEfiVariables = true;
      efiSysMountPoint = "/efi";
    };
  };
}
