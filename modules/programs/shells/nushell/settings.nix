{
  delib,
  const,
  ...
}:
delib.module {
  name = "nushell.settings";

  options = delib.singleEnableOption false;

  home.ifEnabled = delib.ifParentEnabled "nushell" {
    programs.nushell = {
      configFile.source = ./config.nu;
      shellAliases = {
        cfg = "cd ${const.nixosConfigPath}";
      };
    };
  };
}
