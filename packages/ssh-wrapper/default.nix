{
  # Snowfall Lib provides a customized `lib` instance with access to your flake's library
  # as well as the libraries available from your flake's inputs.
  # lib,
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
with pkgs;
  symlinkJoin {
    name = builtins.baseNameOf ./.;
    paths = [
      openssh
      songpola.ssh-win
    ];
    postBuild = ''
      # Rename ssh to ssh-wsl
      mv $out/bin/ssh $out/bin/ssh-wsl

      # ssh
      # WSL:      $out/bin/ssh-wsl -> ${pkgs.openssh}/bin/ssh
      # Windows:  $out/bin/ssh-win -> /mnt/c/Windows/System32/OpenSSH/ssh.exe
      ln -s $out/bin/ssh-win $out/bin/ssh

      # ssh-add
      mv $out/bin/ssh-add $out/bin/ssh-add-wsl
      ln -s /mnt/c/Windows/System32/OpenSSH/ssh-add.exe $out/bin/ssh-add

      # ssh-keygen
      mv $out/bin/ssh-keygen $out/bin/ssh-keygen-wsl
      ln -s /mnt/c/Windows/System32/OpenSSH/ssh-keygen.exe $out/bin/ssh-keygen
    '';
  }
