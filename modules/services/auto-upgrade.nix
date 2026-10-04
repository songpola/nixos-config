{
  # Pull-based auto upgrade: follow the committed flake.lock on `main`.
  # The lock is bumped by .github/workflows/update-flake-lock.yml, never on the host.
  den.aspects.services.auto-upgrade = {
    nixos =
      { host, ... }:
      {
        system.autoUpgrade = {
          enable = true;
          flake = "github:songpola/nixos-config#${host.name}";
          # Always refetch `main` instead of using the cached tarball
          flags = [ "--refresh" ];
          operation = "switch";
          dates = "04:00";
          randomizedDelaySec = "30min";
          # Run on next boot if the timer was missed while powered off
          persistent = true;
        };
      };

    # Reboot after an upgrade only when the kernel, initrd or kernel modules changed.
    _.allow-reboot = {
      nixos.system.autoUpgrade = {
        allowReboot = true;
        rebootWindow = {
          lower = "03:00";
          upper = "06:00";
        };
      };
    };
  };
}
