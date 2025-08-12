{
  delib,
  ...
}:
delib.module {
  name = "bash";

  options = delib.singleEnableOption false;

  home.ifEnabled = {
    programs.bash.enable = true;
  };
}
