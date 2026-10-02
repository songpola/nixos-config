{
  den.aspects.programs.micro = {
    nixos =
      { pkgs, ... }:
      {
        environment.systemPackages = [ pkgs.micro ];
      };

    homeManager.programs.micro = {
      enable = true;
      settings.clipboard = "terminal";
    };

    _.default-editor = {
      nixos.environment.variables.EDITOR = "micro";
    };
  };
}
