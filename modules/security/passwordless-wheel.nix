{
  den.aspects.security.passwordless-wheel.nixos = {
    # Allow "wheel" group members to use `sudo` and manage system services without password
    # Credit: https://wiki.nixos.org/wiki/Polkit#No_password_for_wheel
    security.sudo.wheelNeedsPassword = false;

    # Wheel users can already become root without a password,
    # so trusting them in the Nix daemon grants nothing extra.
    # Needed for remote deploys (`nh os ... --target-host`), to prevent
    # `error: cannot ... because it lacks a signature by a trusted key`.
    nix.settings.trusted-users = [ "@wheel" ];

    # Same trust as passwordless sudo, but only for systemd (systemctl, isd).
    # Takes effect where polkit is enabled (security.polkit aspect).
    security.polkit.extraConfig = ''
      polkit.addRule(function(action, subject) {
        if (action.id.indexOf("org.freedesktop.systemd1.") == 0 && subject.isInGroup("wheel"))
          return polkit.Result.YES;
      });
    '';
  };
}
