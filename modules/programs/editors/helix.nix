{
  delib,
  pkgs,
  ...
}:
delib.module {
  # helix - A post-modern modal text editor
  # https://github.com/helix-editor/helix
  name = "helix";

  options = delib.singleEnableOption false;

  nixos.ifEnabled = {
    environment = {
      systemPackages = [ pkgs.helix ];
      sessionVariables.EDITOR = "hx"; # set as default editor
    };
  };

  home.ifEnabled = {
    programs.helix.enable = true;
  };
}
