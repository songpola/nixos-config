{
  delib,
  pkgs,
  ...
}:
delib.module {
  name = "vscode-remote";

  options = delib.singleEnableOption false;

  nixos.ifEnabled = {
    # Setup VSCode Remote
    environment.systemPackages = [ pkgs.wget ];
    programs.nix-ld.enable = true;
  };
}
