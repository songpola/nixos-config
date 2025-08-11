{ delib, const, ... }:
delib.module {
  name = "localization";

  nixos.always = {
    time.timeZone = const.timeZone;
    environment.variables.TZ = const.timeZone;
  };
}
