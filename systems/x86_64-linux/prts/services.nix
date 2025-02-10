{
  services = {
    openssh = {
      enable = true;
      settings = {
        ClientAliveInterval = 30;
        ClientAliveCountMax = 5;
        TCPKeepAlive = "yes";
      };
    };

    tailscale = {
      enable = true;
      openFirewall = true;
      useRoutingFeatures = "server";
      extraSetFlags = [
        "--advertise-routes=10.0.0.0/16"
        "--advertise-exit-node"
        "--operator=songpola"
        "--ssh"
      ];
    };

    nix-serve = {
      enable = true;
      openFirewall = true;
    };

    syncthing = {
      enable = true;
      openDefaultPorts = true;
      overrideDevices = false;
      overrideFolders = false;
    };
  };
}
