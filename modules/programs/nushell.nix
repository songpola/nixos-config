{ lib, den, ... }:
{
  den.aspects.programs.nushell = {
    homeManager.programs.nushell = {
      enable = true;
      configFile.source = ./nushell-config.nu;
    };

    includes = [
      # Use custom aliases instead
      den.aspects.programs.eza.no-nushell-integration
    ];

    # Bash stays the login shell (NixOS-WSL logs in through it); nushell is
    # exec'd from bash instead of being set as the user's shell.
    _.auto-exec-from-bash-on-login = {
      homeManager.programs.bash = {
        enable = true;
        initExtra = lib.mkOrder 3000 ''
          # Check if we're in a login shell and if nushell is available, then exec it.
          if shopt -q login_shell && command -v nu >/dev/null 2>&1; then
            exec nu
          fi
        '';
      };
    };
  };
}
