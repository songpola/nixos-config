{
  enable = true;
  secrets = [
    {
      path = ".config/sops/age/keys.txt";
      reference = "op://nixos-config/sops-nix-age-key/credential";
    }
  ];
}
