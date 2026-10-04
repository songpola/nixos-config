{
  den.default = {
    nixos.nixpkgs.config.allowUnfree = true;

    nixos.nix = {
      settings.experimental-features = [
        "flakes"
        "nix-command"
        "pipe-operators"
      ];
      registry = {
        "unstable".to = {
          type = "github";
          owner = "NixOS";
          repo = "nixpkgs";
          ref = "nixos-unstable";
        };
        "templates".to = {
          type = "github";
          owner = "songpola";
          repo = "templates";
        };
      };
    };
  };
}
