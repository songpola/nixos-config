{
  delib,
  host,
  lib,
  ...
}:
delib.module {
  name = "presets.stdenv";

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
    |> map (name: delib.attrset.setAttrByStrPath "${name}.enable" true)
    |> lib.mkMerge;
}
