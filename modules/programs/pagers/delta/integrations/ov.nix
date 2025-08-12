{
  delib,
  ...
}:
delib.module {
  name = "delta.integrations.ov";

  options = { myconfig, ... }@args: delib.singleEnableOption myconfig.ov.enable args;

  nixos.ifEnabled = {
    # -F, --quit-if-one-screen: Quit if one screen
    # NOTE: No need to use `--raw` option; ov can handle the escape sequences
    environment.sessionVariables.DELTA_PAGER = "ov -F";
  };
}
