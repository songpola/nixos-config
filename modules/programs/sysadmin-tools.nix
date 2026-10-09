{
  # Diagnostic tools; inspection only, lasting changes belong in the config.
  # Network tools for every host, sub-aspects for hosts with real hardware.
  den.aspects.programs.sysadmin-tools = {
    nixos =
      { pkgs, ... }:
      {
        # mtr-packet needs raw sockets; the module installs it with a capability wrapper
        programs.mtr.enable = true;

        environment.systemPackages = with pkgs; [
          iperf3
          tcpdump # run with sudo
        ];
      };

    # Disks, sensors, buses and NICs; useless in WSL
    _.hardware.nixos =
      { pkgs, ... }:
      {
        environment.systemPackages = with pkgs; [
          smartmontools # smartctl
          nvme-cli # nvme
          hdparm
          lm_sensors # sensors
          pciutils # lspci
          usbutils # lsusb
          dmidecode
          ethtool
        ];
      };

    # Per-disk and per-process I/O
    _.performance.nixos =
      { pkgs, ... }:
      {
        # iotop needs CAP_NET_ADMIN (taskstats); the module installs it with a capability wrapper
        programs.iotop.enable = true;

        environment.systemPackages = with pkgs; [
          sysstat # iostat, pidstat, sar (without data: services.sysstat isn't enabled)
        ];
      };
  };
}
