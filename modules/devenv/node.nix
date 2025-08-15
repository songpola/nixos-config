{
  delib,
  lib,
  ...
}:
delib.module {
  name = "devenv.node";

  options = delib.singleEnableOption false;

  myconfig.ifEnabled =
    [
      "nodejs"
      "nodejs.corepack"
      "bun"
    ]
    |> map (name: delib.setAttrByStrPath "${name}.enable" true)
    |> lib.mkMerge;
}
