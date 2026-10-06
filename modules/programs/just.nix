{
  den.aspects.programs.just = {
    nixos =
      { pkgs, ... }:
      {
        environment.systemPackages = [ pkgs.just ]; # replace make
      };

    _.lsp.nixos =
      { pkgs, ... }:
      {
        environment.systemPackages = [ pkgs.just-lsp ];
      };
  };
}
