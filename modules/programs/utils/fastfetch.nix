{
  delib,
  pkgs,
  host,
  ...
}:
delib.module {
  # fastfetch - A maintained, feature-rich and performance oriented, neofetch like system information tool.
  # https://github.com/fastfetch-cli/fastfetch
  name = "fastfetch";

  options = delib.singleEnableOption host.minienvFeatured;

  nixos.ifEnabled = {
    environment.systemPackages = [ pkgs.fastfetch ];
  };
}
