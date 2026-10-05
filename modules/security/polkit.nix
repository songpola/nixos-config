{
  # Lets unprivileged programs ask privileged daemons (e.g. systemd) to act;
  # without it, systemd denies every non-root `systemctl start/stop/restart`
  den.aspects.security.polkit.nixos.security.polkit.enable = true;
}
