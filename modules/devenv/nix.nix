{
  delib,
  host,
  lib,
  ...
}:
delib.module {
  name = "devenv.nix";

  options = delib.singleEnableOption host.devenvNixFeatured;

  myconfig.ifEnabled =
    [
      "nil" # LSP
      "nixfmt" # formatter
    ]
    |> map (name: delib.setAttrByStrPath "${name}.enable" true)
    |> lib.mkMerge;
}
