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
      # Shells
      "carapace"
      "direnv"
      "nushell.settings"
      "shells.integrations.bashExecNushell"
      "starship"

      # Tools
      "bat.batman"
      "delta"
      "doggo"
      "fzf"
      "httpie"
      "isd"
      "just"
      "lsof"
      "sops"
      "zoxide"
    ]
    |> map (name: delib.setAttrByStrPath "${name}.enable" true)
    |> lib.mkMerge;
}
