{
  delib,
  host,
  ...
}:
delib.module {
  name = "nvidia";

  options = delib.singleEnableOption host.nvidiaFeatured;

  nixos.ifEnabled =
    { cfg, ... }:
    {
      hardware.graphics.enable = true;
      services.xserver.videoDrivers = [ "nvidia" ];
    };
}
