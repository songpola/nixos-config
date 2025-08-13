{
  delib,
  lib,
  pkgs,
  ...
}:
let
  starshipInit = pkgs.runCommand "starship-nushell-config.nu" { } ''
    ${lib.getExe pkgs.starship} init nu >> $out
  '';
in
delib.module {
  name = "starship.integrations.nushell";

  options = delib.singleEnableOptionDependency "nushell";

  home.ifEnabled = {
    programs.nushell.extraConfig = ''
      if ($env.TERM != "dumb" and $env.TERM != "linux") {
          source ${starshipInit}
      }
    '';
  };
}
