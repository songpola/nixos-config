{ delib, inputs, ... }:
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
      registry.self.flake = inputs.self;
    };

    nixpkgs.config.allowUnfree = true;
  };
}
