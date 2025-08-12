{
  delib,
  lib,
  pkgs,
  ...
}:
delib.module {
  name = "starship.integrations.nushell";

  options = { myconfig, ... }@args: delib.singleEnableOption myconfig.nushell.enable args;

  home.ifEnabled = {
    programs.nushell.extraConfig =
      let
        starshipInit = pkgs.runCommand "starship-nushell-config.nu" { } ''
          ${lib.getExe pkgs.starship} init nu >> $out
        '';
      in
      ''
        if ($env.TERM != "dumb" and $env.TERM != "linux") {
            source ${starshipInit}
        }
      '';
  };
}
