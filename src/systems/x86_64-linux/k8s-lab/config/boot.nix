{inputs}: {
  loader = {
    grub = {
      device = "nodev";
      efiSupport = true;
    };
    efi = {
      canTouchEfiVariables = true;
      efiSysMountPoint = inputs.config.disko.devices.disk.main.content.partitions.ESP.content.mountpoint;
    };
  };
}
