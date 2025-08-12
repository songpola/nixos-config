{
  delib,
  ...
}:
delib.module {
  name = "direnv";

  options = delib.singleEnableOption false;

  nixos.ifEnabled = {
    # nix-direnv is enabled by default
    programs.direnv.enable = true;
  };

  home.ifEnabled = {
    programs.direnv = {
      enable = true;
      nix-direnv.enable = true;
    };
  };
}
