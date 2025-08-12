{
  delib,
  ...
}:
delib.module {
  name = "eza.integrations.nushell";

  options = { myconfig, ... }@args: delib.singleEnableOption myconfig.nushell.enable args;

  home.ifEnabled = {
    # IDK why but this default to false
    programs.eza.enableNushellIntegration = true;
  };
}
