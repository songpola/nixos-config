{
  delib,
  lib,
  ...
}:
delib.module {
  name = "devenv.nickel";

  options = delib.singleEnableOption false;

  myconfig.ifEnabled =
    [
      "nickel"
      "nls" # LSP
    ]
    |> map (name: delib.setAttrByStrPath "${name}.enable" true)
    |> lib.mkMerge;
}
