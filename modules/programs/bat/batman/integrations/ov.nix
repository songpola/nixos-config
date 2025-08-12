{
  delib,
  ...
}:
delib.module {
  name = "bat.batman.integrations.ov";

  options = { myconfig, ... }@args: delib.singleEnableOption myconfig.ov.enable args;

  nixos.ifEnabled = {
    # For batman command
    environment.sessionVariables = {
      MANPAGER = "ov --section-delimiter '^[^\\s]'";
    };
  };
}
