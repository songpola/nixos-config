{
  delib,
  username,
  ...
}:
delib.module {
  name = "libvirtd";

  options = delib.singleEnableOption false;

  nixos.ifEnabled = {
    virtualisation.libvirtd.enable = true;
    users.users.${username}.extraGroups = [ "libvirtd" ];
  };
}
