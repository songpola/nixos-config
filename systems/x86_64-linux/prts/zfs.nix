{
  boot = {
    supportedFilesystems = ["zfs"];
    zfs = {
      forceImportRoot = false;
      extraPools = ["tank"];
      devNodes = "/dev/disk/by-partlabel";
    };
  };
  networking.hostId = "eb8b6756";
}
