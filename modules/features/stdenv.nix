{
  delib,
  host,
  lib,
  ...
}:
delib.module {
  name = "stdenv";

  options = delib.singleEnableOption host.stdenvFeatured;

  myconfig.ifEnabled =
    [
      "bat.batman"
      "btop"
      "carapace"
      "delta"
      "direnv"
      "doggo"
      "fzf"
      "helix"
      "httpie"
      "isd"
      "just"
      "lsof"
      "nushell.settings"
      "shells.integrations.bashExecNushell"
      "sops"
      "ssh"
      "starship.settings"
      "starship"
      "zellij"
      "zoxide"
    ]
    |> map (name: delib.setAttrByStrPath "${name}.enable" true)
    |> lib.mkMerge;
}
