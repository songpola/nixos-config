{
  delib,
  host,
  lib,
  ...
}:
delib.module {
  name = "devenv.node";

  options = delib.singleEnableOption host.devenvNodeFeatured;

  myconfig.ifEnabled =
    [
      "nodejs"
      "nodejs.corepack"
      "bun"
    ]
    |> map (name: delib.setAttrByStrPath "${name}.enable" true)
    |> lib.mkMerge;
}
