{
  delib,
  ...
}:
delib.module {
  # bat - a cat(1) clone with wings
  # https://github.com/sharkdp/bat
  name = "bat";

  options = delib.singleEnableOption false;

  nixos.ifEnabled = {
    programs.bat.enable = true;
  };

  home.ifEnabled = {
    programs.bat.enable = true;
  };
}
