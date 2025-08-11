{
  delib,
  pkgs,
  host,
  ...
}:
delib.module {
  name = "vscode-remote";

  options = delib.singleEnableOption host.minienvFeatured;

  nixos.ifEnabled = {
    # Setup VSCode Remote
    environment.systemPackages = [ pkgs.wget ];
    programs.nix-ld.enable = true;
  };
}
