{
  delib,
  host,
  lib,
  ...
}:
delib.module {
  name = "presets.devenv.nix";

  options = delib.singleEnableOption host.stdenvFeatured;

  myconfig.ifEnabled =
    [
      "nil" # LSP
      "nixfmt" # formatter
    ]
    |> map (name: delib.attrset.setAttrByStrPath "${name}.enable" true)
    |> lib.mkMerge;
}
