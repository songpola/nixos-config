{
  den.aspects.programs.delta = {
    nixos =
      { pkgs, ... }:
      {
        environment.systemPackages = [ pkgs.delta ];
      };

    homeManager.programs.delta.enable = true;

    _.default-pager-for-git = {
      homeManager.programs.delta.enableGitIntegration = true;
    };

    _.default-pager-for-jujutsu = {
      homeManager.programs.delta.enableJujutsuIntegration = true;
    };
  };
}
