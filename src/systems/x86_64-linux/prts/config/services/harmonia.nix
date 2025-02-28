{
  config,
  _lib,
}: let
  harmoniaSecret = _lib.sops-nix.mkSecretPath config "harmonia/prts-1/secret";
in {
  enable = true;
  signKeyPaths = [
    harmoniaSecret
  ];
}
