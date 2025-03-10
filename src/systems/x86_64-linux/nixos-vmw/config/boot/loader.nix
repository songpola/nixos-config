{config}: {
  grub = {
    device = "nodev";
    efiSupport = true;
  };
  efi = {
    canTouchEfiVariables = true;
    efiSysMountPoint = config.disko.devices.disk.main.content.partitions.ESP.content.mountpoint;
  };
}
