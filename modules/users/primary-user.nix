{ lib, ... }:
{
  # https://github.com/denful/den/blob/main/modules/aspects/batteries/primary-user.nix
  den.aspects.primary-user =
    { host, user }:
    {
      name = "primary-user(${user.userName}@${host.name})";

      wsl.defaultUser = user.userName;

      # On WSL hosts, wsl.defaultUser (above) defines the user. Elsewhere, define it here.
      # This config shall mirror the wsl.defaultUser implementation, to keep it consistent.
      # Except they're all lib.mkDefault, so that they can be overridden by other aspects.
      user = lib.optionalAttrs (!(host.wsl.enable or false)) {
        isNormalUser = true;
        uid = lib.mkDefault 1000;
        extraGroups = [ "wheel" ];
      };
    };
}
