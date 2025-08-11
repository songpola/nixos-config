{ delib, ... }:
delib.module {
  name = "nix";

  nixos.always = {
    nix = {
      channel.enable = false;
      settings.experimental-features = [
        "flakes"
        "nix-command"
        "pipe-operators"
      ];
    };
  };
}
