{
  delib,
  host,
  lib,
  ...
}:
delib.module {
  name = "shells.integrations.bashExecNushell";

  options = delib.singleEnableOption host.stdenvFeatured;

  home.ifEnabled = {
    programs.bash = {
      # Need to use mkOrder 2000 because zoxide options use mkOrder 2000
      initExtra = lib.mkOrder 3000 ''
        # Use nushell in place of bash unless FORCEBASH is set
        if [[ -z "$FORCEBASH" ]] && command -v nu >/dev/null 2>&1; then
          exec nu
        fi
      '';
    };
  };
}
