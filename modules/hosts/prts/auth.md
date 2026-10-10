# Central auth on PRTS

One login for the web services on PRTS: Kanidm (passkeys) as the only identity provider,
oauth2-proxy as Caddy's forward-auth gate. Access stays Tailscale-only
(`*.songpola.dev A <Tailscale IP>`). Configured in `auth.nix`; the reusable parts are
`services.kanidm`, `services.oauth2-proxy` and `services.caddy-reverse-proxy`.

## Decisions

- **Kanidm** is the only identity provider (users, groups, passkeys, OIDC, LDAP). Authelia
  was dropped: its passkeys count as one factor, it can't take Kanidm as an upstream, and
  it would duplicate Kanidm.
- **Native, not a container**, so `provision` declares persons, groups and OIDC clients in
  Nix. Package `kanidmWithSecretProvisioning_<version>`: its patches let sops supply OIDC
  client secrets (`basicSecretFile`) and the `admin` / `idm_admin` passwords (without them,
  provisioning resets `idm_admin` on every start).
- **Version**: Kanidm only upgrades to the adjacent release (each one migrates the
  database), and nixpkgs marks a release vulnerable 30 days after its successor ships. The
  version is one explicit setting in `auth.nix`; the weekly flake.lock PR bumps it by one
  when the new nixpkgs has the next release.
- **Domains**: `idm.songpola.dev` (Kanidm; passkeys are bound to it, never change it),
  `auth.songpola.dev` (oauth2-proxy).
- **TLS**: Kanidm serves TLS itself with its own certificate from the
  `security.acme-cloudflare` account (DNS-01, shared with Caddy), restarted on renewal.
  Caddy proxies to `https://host.containers.internal:8443` and verifies it
  (`tls_server_name idm.songpola.dev`).
- **Networking**: Kanidm binds 8443 (and LDAPS 636) on all addresses; the firewall opens
  them to `podman*` bridges. The LAN stays blocked, but Tailscale accepts everything on
  `tailscale0`, so the tailnet reaches them directly (fine for an IdP with its own TLS;
  limit shared users in the ACL, see TODO). On the `caddy` network `idm.songpola.dev` is a
  network alias of Caddy, so containers reach Kanidm through Caddy, not via the host's
  Tailscale address.
- **Storage**: database in `/var/lib/kanidm` on the root SSD; Kanidm starts after
  `zfs-mount.service` without requiring it, so login survives a failed pool import. Online
  backups (daily, `22:00` UTC) go to `/tank/v2/services/kanidm/backups`.
- **Groups**: apps gate on `prts_admins` and `prts_media`, never on Kanidm's built-in
  groups (`idm_admins` etc. grant Kanidm admin rights, not app access). Kanidm sends groups
  by SPN: `prts_admins@idm.songpola.dev`.

## The gate

Sites opt in with `caddy.import: auth <group>` (Nix-managed services through a
`forward-auth` sub-aspect). The `auth` snippet comes from the oauth2-proxy aspect:
`forward_auth` to `oauth2-proxy:4180/oauth2/auth?allowed_groups=<group>`; 401 redirects to
the login; `copy_headers` replaces client-supplied `X-Auth-Request-*`. oauth2-proxy uses
OIDC with PKCE S256, one `.songpola.dev` cookie for all sites, and doesn't log the
forward-auth checks.

## App logins

| App | Gate | Own login |
|---|---|---|
| Dockhand | `prts_admins` | OIDC client `dockhand` (provider set in its UI), autologin, local login hidden (`/login?local=1`) |
| Dozzle | `prts_admins` | forward-proxy mode, user from the gate's headers |
| Sonarr, Radarr, Prowlarr | `prts_admins` | `<APP>__AUTH__METHOD=External` (API still needs its key) |
| qBittorrent | `prts_admins` | bypassed for the `caddy` subnet (set in its UI, no env var); the apps still log in with its password |
| qui | `prts_admins` | `QUI__AUTH_DISABLED` for the `caddy` subnet and `qui.songpola.dev` only (chosen over OIDC: a client secret would have to live outside the public repo) |
| Clonarr | `prts_admins` | none of its own |
| Jellyfin | none (TV/phone apps can't do a browser login) | LDAP plugin against Kanidm |

The apps reach each other on their stack network, never through Caddy, so plain `auth` is
enough. Only API clients from outside (phone apps, calendar feeds) would need an
`auth-arr` variant that skips `/api/*` and `/feed/*`.

The `caddy` subnet (`10.89.1.0/24`) isn't pinned in Nix: if the network is recreated with
another subnet, qui refuses and qBittorrent asks for its login (both fail closed). Keep
qBittorrent's "reverse proxy support" off: the bypass must see Caddy's address, not the
forwarded client.

## Jellyfin and LDAP

Kanidm serves read-only LDAPS on 636 (`services.kanidm.ldapPort`, same certificate).
Jellyfin maps `idm.songpola.dev` to the host (`extra_hosts: host-gateway`), since on the
`caddy` network the name resolves to Caddy, which doesn't carry LDAP.

Official "LDAP Authentication" plugin: `idm.songpola.dev:636`, secure LDAP, TLS verified,
base `dc=idm,dc=songpola,dc=dev`, filter
`(&(class=person)(memberof=spn=prts_media@idm.songpola.dev,dc=idm,dc=songpola,dc=dev))`,
admin filter the same with `prts_admins`, search/username attribute `name`, uid attribute
`uuid`, user creation on.

- It searches **anonymously** (empty bind user). Kanidm lets anonymous read name,
  `memberof` and `uuid`; an API token's service account sees no people unless added to a
  group, and the only one that helps (`idm_people_pii_read`) grants more than needed.
- Users log in with their Kanidm name and **POSIX password** (LDAP never accepts passkeys).
  POSIX attributes aren't provisionable from Nix:
  ```nu
  kanidm person posix set <name> -D idm_admin
  kanidm person posix set-password <name> -D idm_admin
  ldapwhoami -H ldaps://idm.songpola.dev -x -D name=<name> -w <password>   # test
  ```
- The SSO plugin was rejected: the original (9p4) is archived, with no successor yet.

## Break-glass

With Dockhand and Dozzle behind Kanidm and oauth2-proxy, an outage of those two locks you
out of the tools you would debug it with: use SSH (Tailscale SSH) and isd. Never use the
`port` option of `services.dockhand` / `services.dozzle` as a way in: a published port
skips the gate for the whole tailnet. Jellyfin has a local admin `admin` (password in
1Password) for LDAP outages.
