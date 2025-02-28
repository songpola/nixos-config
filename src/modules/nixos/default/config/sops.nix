{
  lib,
  config,
  _lib,
}: {
  age.keyFile = _lib.opnix.mkSecretPath config "sops-nix-age-key";
  inherit (_lib.sops-nix) defaultSopsFile;
}
