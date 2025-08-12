{
  delib,
  pkgs,
  const,
  ...
}:
delib.module {
  # ov - feature rich terminal pager
  # https://github.com/noborus/ov
  name = "ov";

  options = delib.singleEnableOption false;

  nixos.ifEnabled = {
    environment = {
      systemPackages = [ pkgs.ov ];

      sessionVariables = {
        PAGER = "ov";

        # Let systemd use this pager
        SYSTEMD_PAGERSECURE = "false";
      };
    };
  };

  home.ifEnabled = {
    xdg.configFile = {
      "ov/config.yaml".source = const.configPath + "/ov/config.yaml";
    };
  };
}
