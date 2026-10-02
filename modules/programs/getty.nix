{ lib, ... }:
{
  den.aspects.programs.getty = {
    settings.autologinUser = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = "User to auto-login on the Linux console (getty)";
    };

    nixos =
      { host, ... }:
      {
        services.getty.autologinUser = host.settings.programs.getty.autologinUser;
      };
  };
}
