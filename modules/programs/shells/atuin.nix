{
  delib,
  ...
}:
delib.module {
  name = "atuin";

  options = delib.singleEnableOption false;

  home.ifEnabled = {
    programs.atuin.enable = true;
  };
}
