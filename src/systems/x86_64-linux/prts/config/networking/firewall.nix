{
  allowedTCPPorts = [
    # caddy
    80
    443
    # harmonia
    5000
    # tsdproxy
    8080
    # syncthing
    8384
    22000
  ];
  allowedUDPPorts = [
    # caddy: HTTP/3
    443
    # syncthing
    21027
    22000
  ];
}
