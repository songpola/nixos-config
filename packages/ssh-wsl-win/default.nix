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
# pkgs.openssh.overrideAttrs (oldAttrs: {
#   postInstall =
#     oldAttrs.postInstall
#     + ''
#       mv $out/bin/ssh $out/bin/ssh.orig
#       ln -sf /mnt/c/Windows/System32/OpenSSH/ssh.exe $out/bin/ssh
#     '';
# })
pkgs.symlinkJoin {
  name = "ssh-wsl-win";
  paths = [pkgs.openssh];
  postBuild = ''
    mv $out/bin/ssh $out/bin/ssh-wsl
    ln -s /mnt/c/Windows/System32/OpenSSH/ssh.exe $out/bin/ssh
  '';
}
