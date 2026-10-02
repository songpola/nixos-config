{
  den.aspects.programs.fzf = {
    nixos =
      { pkgs, ... }:
      {
        environment.systemPackages = [ pkgs.fzf ];
      };

    homeManager.programs.fzf.enable = true;
  };
}
