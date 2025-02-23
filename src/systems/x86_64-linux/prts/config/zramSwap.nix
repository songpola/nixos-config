{config}: {
  enable = true;
  writebackDevice = config.disko.devices.disk.main.content.partitions.zramSwap.device;
}
