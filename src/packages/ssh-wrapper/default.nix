{
  pkgs,
  writeShellApplication,
  ...
}:

writeShellApplication {
  name = "ssh";
  runtimeInputs = with pkgs; [ openssh ];
  text = ''
    echo started
    echo "$@"
    exec ssh "$@"
  '';
}
