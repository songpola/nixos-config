{ delib, pkgs, ... }:
delib.module {
  name = "services.netdata";

  options = delib.singleEnableOption false;

  nixos.ifEnabled = {
    services.netdata = {
      enable = true;
      package = pkgs.netdataCloud;
      # config.global = {
      #   "memory mode" = "ram";
      #   "debug log" = "none";
      #   "access log" = "none";
      #   "error log" = "syslog";
      # };
    };

    networking.firewall.allowedTCPPorts = [ 19999 ];
  };
}
