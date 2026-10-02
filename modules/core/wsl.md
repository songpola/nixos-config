# WSL

Internal WSL battery ([wsl.nix](wsl.nix)). It replaces den's built-in one. The
public hook is the aspect **`den.aspects.wsl`**.

## Enable

```nix
den.hosts.x86_64-linux.my-host.wsl.enable = true;
```

The `nixos-wsl` input is declared in `wsl.nix`, pinned to
`release-${stableVersion}`. Set `host.wsl.module` to use a different NixOS-WSL
module. Only `nixos` class hosts are supported.

## WSL-only config

Anything set on `den.aspects.wsl` applies on WSL hosts and to each of their
users, so every class key works, `homeManager` included. Set keys directly, or
include other named aspects:

```nix
den.aspects.wsl = {
  nixos.wsl.extraBin = [ { src = "/usr/bin/env"; } ];
  homeManager.home.sessionVariables.IS_WSL = "1";
  includes = [ den.aspects.wsl-extras ];
};
```

It applies to every user on the host. For one user only, include the aspect
from that user's aspect, guarded by `host.wsl.enable`
(see `songpola/wsl-commit-signing` in [../users/songpola.nix](../users/songpola.nix)).

## Rules

`den.aspects.wsl` is included at host scope and again at every user scope. Den
dedupes `nixos` content across scopes by aspect name only.

| Content in `den.aspects.wsl` (or its includes) | List option result |
| ---------------------------------------------- | ------------------ |
| `nixos.wsl.extraBin`                           | once               |
| `wsl.extraBin` (class key)                     | **twice**          |
| anonymous `{ ... }` in `includes`              | **twice**          |

1. Only put **named aspects** (`den.aspects.<name>`) in
   `den.aspects.wsl.includes`, never inline attrsets.
2. Inside `den.aspects.wsl` and anything it includes, set NixOS-WSL options as
   `nixos.wsl.*`, not through the `wsl` class key. Routed `wsl` content isn't
   deduped across scopes (a den bug, also present in den's own battery).
3. Aspects included exactly once may use the `wsl` class key, e.g.
   `primary-user`'s `wsl.defaultUser`.

Duplicate scalars merge harmlessly; duplicate list values are doubled.

## Why not den's battery

Den's battery resolves a derived `wsl-host` entity beside the user scopes, so
`homeManager` keys in `den.schema.wsl-host.includes` were silently dropped. This
module has no such entity: it includes `den.aspects.wsl` at the host and at every
user. Den's two policies (`host-to-wsl-host`, `wsl-to-host`) are disabled through
`den.schema.host.excludes` and `den.default.excludes`, so
`den.schema.wsl-host.includes` does nothing in this repo.
