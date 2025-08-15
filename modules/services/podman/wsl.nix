{
  delib,
  host,
  username,
  ...
}:
delib.module {
  name = "podman.wsl";

  options = delib.singleEnableOption host.isWsl;

  nixos.ifEnabled = delib.ifParentEnabled "podman" {
    # Remote: NixOS-WSL -> Podman Desktop
    # https://podman-desktop.io/docs/podman/accessing-podman-from-another-wsl-instance
    users.groups = {
      # For podman-machine-default-root connection
      podman-machine-root = {
        gid = 10;
        members = [ username ];
      };
      # For podman-machine-default connection
      podman-machine-user = {
        gid = 1000;
        members = [ username ];
      };
    };
  };
}
