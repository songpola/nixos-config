{
  lib,
  config,
  _lib,
}: {
  age.keyFile = _lib.getOpnixSecret config "sops-nix-age-key";
  defaultSopsFile = _lib.secrets.sops-nix;
}
