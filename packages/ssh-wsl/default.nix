{
  # Snowfall Lib provides a customized `lib` instance with access to your flake's library
  # as well as the libraries available from your flake's inputs.
  lib,
  # You also have access to your flake's inputs.
  # inputs,
  # The namespace used for your flake, defaulting to "internal" if not set.
  # namespace,
  # All other arguments come from NixPkgs. You can use `pkgs` to pull packages or helpers
  # programmatically or you may add the named attributes as arguments here.
  pkgs,
  # stdenv,
  ...
}:
pkgs.linkFarm (builtins.baseNameOf ./.) (
  lib.mapAttrsToList (name: path: {
    name = "bin/${name}";
    path = path;
  }) {
    ssh = "/mnt/c/Windows/System32/OpenSSH/ssh.exe";
    ssh-add = "/mnt/c/Windows/System32/OpenSSH/ssh-add.exe";
    ssh-keygen = "/mnt/c/Windows/System32/OpenSSH/ssh-keygen.exe";
  }
)
