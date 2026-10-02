{
  den.aspects.programs.jujutsu = {
    nixos =
      { pkgs, ... }:
      {
        environment.systemPackages = [ pkgs.jujutsu ];
      };

    homeManager.programs.jujutsu.enable = true;
  };
}
