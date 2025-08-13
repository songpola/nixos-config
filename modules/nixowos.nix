{
  delib,
  inputs,
  ...
}:
delib.module {
  name = "nixowos";

  options = delib.singleEnableOption false;

  nixos.always.imports = [ inputs.nixowos.nixosModules.default ];

  nixos.ifEnabled = {
    # FIXME: fastfetch patch doesn't work
    nixowos = {
      # Make this system *cute* ( •̀ ω •́ )✧
      enable = true;

      # NOTE: Starship prompt don't know NixOwOS and will show default linux icon
      os-release.enable = false;
    };
  };
}
