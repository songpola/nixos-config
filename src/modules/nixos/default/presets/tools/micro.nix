{
  lib,
  config,
  namespace,
  pkgs,
  ...
}:
lib.${namespace}.mkPresetModule2 config [ "tools" "micro" ] {
  systemConfig = [
    {
      # micro - A modern and intuitive terminal-based text editor
      # https://github.com/zyedidia/micro
      environment.systemPackages = [ pkgs.micro ];

      # Set as default editor
      environment.variables = {
        EDITOR = "micro";
      };
    }
  ];
  homeConfig = [
    {
      programs.micro = {
        enable = true;
        settings = {
          # Fix clipboard not working in SSH sessions:
          # Use OSC 52 (terminal clipboard)
          clipboard = "terminal";
        };
      };
    }
  ];
}
