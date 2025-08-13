{
  delib,
  const,
  ...
}:
delib.module {
  # nh - Yet another Nix CLI helper
  # https://github.com/nix-community/nh
  name = "nh";

  options = delib.singleEnableOption false;

  nixos.ifEnabled = {
    programs.nh = {
      enable = true;
      flake = const.nixosConfigPath;
    };
  };
}
