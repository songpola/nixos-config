{
  config,
  _lib,
}: {
  enable = true;
  environmentFile = _lib.sops-nix.mkSecretPath config "atticd.env";
}
