{config}: {
  enable = true;
  writebackDevice = config.disko.devices.disk.main.content.partitions.swap.device;
}
