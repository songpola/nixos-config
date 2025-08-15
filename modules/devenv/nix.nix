{
  delib,
  lib,
  ...
}:
delib.module {
  name = "devenv.nix";

  options = delib.singleEnableOption false;

  myconfig.ifEnabled =
    [
      "nil" # LSP
      "nixfmt" # formatter
    ]
    |> map (name: delib.setAttrByStrPath "${name}.enable" true)
    |> lib.mkMerge;
}
