{
  delib,
  ...
}:
delib.module {
  name = "eza.integrations.nushell";

  options = delib.singleEnableOptionDependency "nushell";

  home.ifEnabled = delib.ifParentEnabled "eza" {
    # IDK why but this default to false
    programs.eza.enableNushellIntegration = true;
  };
}
