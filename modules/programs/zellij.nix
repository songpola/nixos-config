{
  den.aspects.programs.zellij = {
    nixos =
      { pkgs, ... }:
      {
        environment.systemPackages = [ pkgs.zellij ];
      };

    homeManager.programs.zellij.enable = true;
  };
}
