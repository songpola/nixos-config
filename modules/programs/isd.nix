{ den, ... }:
{
  # isd (interactive systemd) TUI
  den.aspects.programs.isd = {
    # isd runs systemctl as the user first and only retries with sudo on an
    # "authentication required" error; without polkit, systemd answers "Access denied"
    # instead, so managing system services fails
    includes = [ den.aspects.security.polkit ];

    nixos =
      { pkgs, ... }:
      {
        environment.systemPackages = [ pkgs.isd ];
      };
  };
}
