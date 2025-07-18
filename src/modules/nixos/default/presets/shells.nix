{
  lib,
  config,
  namespace,
  ...
}:
let
  inherit (lib.${namespace}) getConfigPath nixosConfigPath;
in
lib.${namespace}.mkPresetModule config [ "shells" ] {
  systemConfig = [
    {
      ${namespace}.presets = {
        tools = {
          zoxide = true;
          # fzf = true; # already enabled by zoxide
          eza = true;
          bat = true;
        };
      };
    }
  ];
  homeConfig = [
    {
      programs.nushell = {
        enable = true;
        configFile.source = getConfigPath "/nushell/config.nu";

        shellAliases = {
          cfg = "cd ${nixosConfigPath}";
        };
      };

      # Use Nushell as the default shell
      programs.bash = {
        enable = true;
        initExtra = ''
          # Use nushell in place of bash
          command -v nu >/dev/null 2>&1 && exec nu
        '';
      };

      # Starship prompt
      programs.starship.enable = true;

      # Carapace completer
      programs.carapace.enable = true;

      # Zoxide
      programs.zoxide.enable = true;
    }
  ];
}
