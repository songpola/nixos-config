{
  delib,
  host,
  ...
}:
delib.module {
  name = "bootable";

  options = delib.singleEnableOption host.bootableFeatured;

  nixos.ifEnabled = {
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
  };
}
