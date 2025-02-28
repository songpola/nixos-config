{
  config,
  _lib,
}: {
  age.keyFile = _lib.secrets.opnix.mkSecretPath config "sops-nix-age-key";
}
