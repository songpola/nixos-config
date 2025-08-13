{
  delib,
  ...
}:
delib.module {
  name = "delta.integrations.ov";

  options = delib.singleEnableOptionDependency "ov";

  nixos.ifEnabled = delib.ifParentEnabled "delta" {
    # -F, --quit-if-one-screen: Quit if one screen
    # NOTE: No need to use `--raw` option; ov can handle the escape sequences
    environment.sessionVariables.DELTA_PAGER = "ov -F";
  };
}
