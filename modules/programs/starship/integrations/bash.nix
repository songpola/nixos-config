{
  delib,
  lib,
  pkgs,
  ...
}:
delib.module {
  name = "starship.integrations.bash";

  options = { myconfig, ... }@args: delib.singleEnableOption myconfig.bash.enable args;

  home.ifEnabled = {
    programs.bash.initExtra = ''
      if [[ $TERM != "dumb" && $TERM != "linux" ]]; then
        eval "$(${lib.getExe pkgs.starship} init bash --print-full-init)"
      fi
    '';
  };
}
