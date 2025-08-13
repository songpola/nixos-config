{
  delib,
  lib,
  ...
}:
delib.module {
  name = "shells.integrations.bashExecNushell";

  options = delib.singleEnableOption false;

  home.ifEnabled = {
    # Need to use mkOrder 2000 because zoxide options use mkOrder 2000
    programs.bash.initExtra = lib.mkOrder 3000 ''
      # Use nushell in place of bash unless FORCEBASH is set
      if [[ -z "$FORCEBASH" ]] && command -v nu >/dev/null 2>&1; then
        exec nu
      fi
    '';
  };
}
