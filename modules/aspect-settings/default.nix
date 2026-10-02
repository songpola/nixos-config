# Typed per-aspect settings, set on hosts. See https://den.denful.dev/guides/aspect-settings/
{ den, lib, ... }:
{
  den.reservedKeys = [ "settings" ];

  den.schema.host.imports = [
    {
      options.settings = lib.mkOption {
        type = import ./_settings-type.nix { inherit den lib; };
        default = { };
        description = "Per-aspect typed settings";
      };
    }
  ];
}
