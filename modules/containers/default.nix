{
  delib,
  host,
  inputs,
  homeconfig,
  ...
}:
delib.module {
  name = "containers";

  options = delib.singleEnableOption host.containersFeatured;

  myconfig.always.args.shared = {
    quadletCfg = homeconfig.virtualisation.quadlet;
  };

  home.always.imports = [ inputs.quadlet-nix.homeManagerModules.quadlet ];

  home.ifEnabled =
    { cfg, ... }:
    {
      virtualisation.quadlet.enable = cfg.enable;
    };
}
