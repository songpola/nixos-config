{
  delib,
  username,
  ...
}:
delib.module {
  name = "tailscale";

  options = delib.singleEnableOption false;

  nixos.ifEnabled = {
    services.tailscale = {
      enable = true;
      openFirewall = true;
      extraSetFlags = [
        "--operator=${username}"
        # # Tailscale SSH is not compatible with Podman yet
        # "--ssh"
      ];
    };
  };
}
