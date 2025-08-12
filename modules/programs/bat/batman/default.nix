{
  delib,
  pkgs,
  ...
}:
delib.module {
  name = "bat.batman";

  options = delib.singleEnableOption false;

  nixos.ifEnabled = {
    # Auto generate the immutable cache for man apropos
    documentation.man.generateCaches = true;
  };

  home.ifEnabled = {
    programs.bat = {
      # NOTE: Need to add batman using Home Manager options
      # to avoid shells integration in NixOS options.
      extraPackages = with pkgs.bat-extras; [ batman ];
    };
  };
}
