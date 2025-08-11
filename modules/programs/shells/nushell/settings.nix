{
  delib,
  host,
  const,
  ...
}:
delib.module {
  name = "nushell.settings";

  options = delib.singleEnableOption host.stdenvFeatured;

  home.ifEnabled = {
    programs.nushell = {
      configFile.source = ./config.nu;
      shellAliases = {
        cfg = "cd ${const.nixosConfigPath}";
      };
    };
  };
}
