{
  delib,
  host,
  inputs,
  ...
}:
delib.module {
  name = "containers";

  options = delib.singleEnableOption host.containersFeatured;

  home.always.imports = [ inputs.quadlet-nix.homeManagerModules.quadlet ];

  home.ifEnabled =
    { cfg, ... }:
    {
      virtualisation.quadlet.enable = cfg.enable;
    };
}
