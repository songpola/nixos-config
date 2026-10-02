{ den, lib, ... }:
{
  # I only use homeManager to manage my home-environment.
  # Other options: hjem, maid
  # `user` is listed too, so that `host-aspects` (below) also forwards the
  # `user` class (`users.users.<name>`) from aspects included by a host.
  den.schema.user.classes = lib.mkDefault [
    "homeManager"
    "user"
  ];

  # Fix the "Host-scope parametric aspects no longer deliver homeManager content to users"
  # https://den.denful.dev/guides/home-manager/#host-scope-parametric-aspects-no-longer-deliver-homemanager-content-to-users
  den.schema.user.includes = [ den.batteries.host-aspects ];

  den.default.includes = [ den.batteries.hostname ];
}
