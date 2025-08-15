{ delib, ... }:
delib.host {
  name = "prts";

  type = "server";
  system = "x86_64-linux";
  features = [
    "stdenv"
    "zfs"
    "nvidia"
  ];

  nixos.system.stateVersion = "24.11";
  home.home.stateVersion = "24.11";

  myconfig = {
    zfs.hostId = "eb8b6756";
    podman.enable = true;
    libvirtd.enable = true;
  };

  nixos = {
    # 1050Ti (Pascal) doesn't support open-source kernel module
    hardware.nvidia.open = false;

    # I don't want to type my password every time I use sudo on this system
    security.sudo.wheelNeedsPassword = false;

    # For Podman rootful containers
    virtualisation.containers.storage.settings = {
      storage = {
        driver = "zfs";
        options.zfs.fsname = "tank/podman";
      };
    };
  };
}
