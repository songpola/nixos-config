{
  lib,
  config,
  namespace,
  ...
}:
lib.${namespace}.mkPresetModule2 config [ "bootable" ] {
  systemConfig = [
    {
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
  ];
}
