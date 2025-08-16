{
  delib,
  ...
}:
delib.module {
  name = "glances";

  options = delib.singleEnableOption false;

  nixos.ifEnabled.services.glances.enable = true;
}
