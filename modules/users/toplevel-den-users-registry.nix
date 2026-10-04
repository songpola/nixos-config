# Top-level user registry: `den.users.<name>` takes the same options as a host
# user (`den.schema.user`), and its definitions apply to every host user of the
# same name, as if written at `den.hosts.<system>.<host>.users.<name>`.
#
# Declare an option once on `den.schema.user`; set it on either side. Both
# sides merge like any module definitions (lists concatenate, scalars must
# agree unless prioritized with `lib.mkDefault`/`lib.mkForce`).
# See https://den.denful.dev/reference/schema/#schema-base-modules
{
  den,
  lib,
  options,
  ...
}:
let
  # Raw definitions of `den.users`, each `{ <user> = { <option> = value; }; }`.
  # Read raw rather than as the merged value, so a host user gets exactly what
  # was written (no defaults that would shadow or conflict with host-level ones).
  defs = options.den.valueMeta.configuration.options.users.definitions;

  # Every option name set on any user. Must not depend on `user`: the module
  # system needs a config's attribute names before evaluating `user` itself.
  definedNames = lib.unique (
    lib.concatMap (def: lib.concatMap builtins.attrNames (builtins.attrValues def)) defs
  );
in
{
  options.den.users = lib.mkOption {
    type = lib.types.attrsOf (
      den.lib.schema.mkInstanceType den.schema.user {
        strict = false;
        # Not on any host; also tells the module below not to apply here.
        extraModules = [ { _module.args.host = null; } ];
      }
    );
    default = { };
    description = "Host-independent user definitions, applied to host users of the same name.";
  };

  config.den.schema.user =
    { user, host, ... }:
    {
      config = lib.genAttrs definedNames (
        name:
        lib.mkMerge (
          map (
            def: lib.mkIf (host != null && (def.${user.name} or { }) ? ${name}) def.${user.name}.${name}
          ) defs
        )
      );
    };
}
