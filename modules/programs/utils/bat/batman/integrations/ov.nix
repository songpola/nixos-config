{
  delib,
  ...
}:
delib.module {
  name = "bat.batman.integrations.ov";

  options = delib.singleEnableOptionDependency "ov";

  nixos.ifEnabled = delib.ifParentEnabled "bat.batman" {
    # For batman command
    environment.sessionVariables = {
      MANPAGER = "ov --section-delimiter '^[^\\s]'";
    };
  };
}
