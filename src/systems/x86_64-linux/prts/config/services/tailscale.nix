{
  enable = true;
  openFirewall = true;
  useRoutingFeatures = "server";
  extraSetFlags = [
    "--advertise-routes=10.0.0.0/16"
    "--advertise-exit-node"
    "--operator=songpola"
    "--ssh"
  ];
}
