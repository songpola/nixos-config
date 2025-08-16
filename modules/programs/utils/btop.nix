{
  delib,
  pkgs,
  host,
  ...
}:
delib.module {
  name = "btop";

  options =
    with delib;
    enableOptionWith false {
      nvidia.enable = boolOption host.nvidiaFeatured;
    };

  nixos.ifEnabled =
    { cfg, ... }:
    {
      environment.systemPackages = [
        (if cfg.nvidia.enable then pkgs.btop-cuda else pkgs.btop)
      ];
    };
}
