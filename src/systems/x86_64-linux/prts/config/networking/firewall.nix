{
  allowedTCPPorts = [
    # caddy
    80
    443
    # harmonia
    5000
    # syncthing
    # 8384
    # tsdproxy
    8080
  ];
  allowedUDPPorts = [
    443 # caddy: HTTP/3
  ];
}
