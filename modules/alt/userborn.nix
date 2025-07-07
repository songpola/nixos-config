{
  # NOTE: Not working with NixOS-WSL when changing wsl.defaultUser

  # Manage users and groups with userborn
  # https://nixos.org/manual/nixos/stable/#sec-userborn
  # https://github.com/nikstur/userborn
  services.userborn.enable = true;
}
