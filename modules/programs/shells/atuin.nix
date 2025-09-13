{
  delib,
  ...
}:
delib.module {
  name = "atuin";

  options = delib.singleEnableOption false;

  home.ifEnabled = {
    # FIXME: Add --disable-up-arrow
    # TODO: Wait until Nushell v0.107 available in nixpkgs
    programs.atuin.enable = true;
  };
}
