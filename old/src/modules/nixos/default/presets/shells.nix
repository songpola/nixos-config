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
          starship = true;
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
        # Need to use mkOrder 2000 because zoxide options use mkOrder 2000
        initExtra = lib.mkOrder 3000 ''
          # Use nushell in place of bash unless FORCE_BASH is set
          if [[ -z "$FORCE_BASH" ]] && command -v nu >/dev/null 2>&1; then
            exec nu
          fi
        '';
      };

      # Carapace completer
      programs.carapace.enable = true;

      # Zoxide
      programs.zoxide.enable = true;
    }
  ];
}
