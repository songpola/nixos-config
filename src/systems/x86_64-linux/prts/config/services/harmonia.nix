{
  config,
  _lib,
}: let
  harmoniaSecret = _lib.secrets.sops-nix.mkSecretPath config "harmonia";
in {
  enable = true;
  signKeyPaths = [
    harmoniaSecret
  ];
}
