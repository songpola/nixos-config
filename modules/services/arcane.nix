# Arcane for managing throwaway lab projects (https://getarcane.app), as a quadlet
# (`quadlet-arcane.service`) with access to the rootful podman socket and the host's system
# D-Bus. Through D-Bus (with settings.user = "root", as in Arcane's rootful Podman example)
# it starts, stops and restarts quadlet containers via their systemd units, so a stop sticks
# instead of being undone by `Restart=always`, and runs podman auto-update (on Podman < 6.2 by
# starting `podman-auto-update.service`). It could also manage any other unit: keep to the
# quadlets, and don't remove Nix's quadlets from its Quadlets page (the next switch restores
# them). Exposed through services.caddy-reverse-proxy at settings.domain.
#
# Projects live in settings.projectsDir, mounted at the same path so compose files with
# relative bind mounts work. Deploy and update them per project, never with a container's
# Redeploy/Edit/Update: on Podman, recreating a single container copies its IP and MAC into
# the new one, which Podman turns into static pins (they collide at boot).
#
# UPGRADING past v2.17: Arcane's next major release renames every config and settings env var
# to `ARCANE_<NAME>` (APP_URL -> ARCANE_APP_URL, OIDC_ENABLED -> ARCANE_OIDC_ENABLED,
# ENCRYPTION_KEY_FILE -> ARCANE_ENCRYPTION_KEY_FILE, ...; getarcaneapp/arcane#4540) and
# doesn't read the old names: rename every Arcane variable below together with the image bump,
# or Arcane silently runs without its encryption key, SSO and projects directory. PUID, PGID
# and TZ keep their names.
{ den, lib, ... }:
let
  name = "arcane";
  unit = "quadlet-${name}.service";
  # Arcane's web UI port inside the container
  containerPort = 3552;
in
{
  den.aspects.services.${name} = {
    includes = [
      den.aspects.programs.quadlet
      den.aspects.services.caddy-reverse-proxy
    ];

    settings = {
      dataDir = lib.mkOption {
        type = lib.types.str;
        default = "/var/lib/${name}";
        description = "Arcane's data directory (/app/data: database, git checkouts)";
      };
      projectsDir = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        example = "/srv/arcane/projects";
        description = ''
          Projects directory (`<projectsDir>/<project>/compose.yaml`), mounted at the same path
          inside; null means `<dataDir>/projects`.
        '';
      };
      user = lib.mkOption {
        type = lib.types.str;
        description = ''
          User (and its primary group) Arcane runs as, which owns the files it writes. Not a
          security boundary: the podman socket already grants root-equivalent access. "root"
          lets it manage systemd units over D-Bus; another user is refused by polkit.
        '';
      };
      podmanGid = lib.mkOption {
        type = lib.types.int;
        default = 991;
        description = ''
          GID to pin the podman group to. Dynamic GIDs are only assigned at activation, so the
          config can't read one; the container needs it (GroupAdd) to use the socket.
        '';
      };
      domain = lib.mkOption {
        type = lib.types.str;
        example = "arcane.example.com";
        description = "Serve Arcane at this domain through services.caddy-reverse-proxy";
      };
      image = lib.mkOption {
        type = lib.types.str;
        # Pinned: the next major release renames the env vars (see the top of this file)
        default = "ghcr.io/getarcaneapp/arcane:v2.17.3";
        description = "Arcane image";
      };
    };

    nixos =
      { config, host, ... }:
      let
        cfg = host.settings.services.${name};
        caddy = host.settings.services.caddy-reverse-proxy;
        userCfg = config.users.users.${cfg.user};
        group = userCfg.group;
        projectsDir = if cfg.projectsDir == null then "${cfg.dataDir}/projects" else cfg.projectsDir;
      in
      {
        users.groups.podman.gid = cfg.podmanGid;

        systemd.tmpfiles.rules = [
          "d ${cfg.dataDir} 0755 ${cfg.user} ${group} -"
          "d ${projectsDir} 0755 ${cfg.user} ${group} -"
        ];

        virtualisation.quadlet.containers."quadlet-${name}".containerConfig = {
          inherit name;
          inherit (cfg) image;
          volumes = [
            "/run/podman/podman.sock:/var/run/docker.sock"
            # systemd control of the quadlet units and podman auto-update (see the top)
            "/run/dbus/system_bus_socket:/run/dbus/system_bus_socket"
            "${cfg.dataDir}:/app/data"
            # Same path inside, so compose files with relative bind mounts work
            "${projectsDir}:${projectsDir}"
          ];
          addGroups = [ (toString cfg.podmanGid) ];
          environments = {
            TZ = if config.time.timeZone == null then "UTC" else config.time.timeZone;
            PUID = toString userCfg.uid;
            PGID = toString config.users.groups.${group}.gid;
            APP_URL = "https://${cfg.domain}";
            PROJECTS_DIRECTORY = projectsDir;
            # Client IPs from Caddy's X-Forwarded-For
            TRUSTED_PROXIES = caddy.subnet;
          };
          # The host's cgroup namespace, as in Arcane's Podman example: Arcane finds its own
          # container from its cgroup path (so bulk actions and self-update leave it alone) and
          # reads memory usage from the host's cgroup tree. No real loss of isolation: the podman
          # socket is root-equivalent anyway.
          podmanArgs = [ "--cgroupns=host" ];
          # Exec form (JSON array): the image has no shell. The unit is ready only once it passes
          healthCmd = ''["./arcane","health","--timeout","2s"]'';
          healthInterval = "10s";
          healthStartPeriod = "15s";
          notify = "healthy";
          stopTimeout = 15;
          networks = [ config.virtualisation.quadlet.networks."quadlet-${caddy.network}".ref ];
          labels = den.aspects.programs.podman.meta.autoUpdateLabels // {
            "caddy" = cfg.domain;
            "caddy.reverse_proxy" = "{{upstreams ${toString containerPort}}}";
            # Dozzle links the container to its web UI
            "dev.dozzle.url" = "https://${cfg.domain}";
            # Not bundled with Dozzle; selfh.st icon (CC BY 4.0, https://selfh.st/icons)
            "dev.dozzle.icon" = den.aspects.programs.quadlet.meta.escapeSpecifiers (
              "data:image/svg+xml," + lib.escapeURL (builtins.readFile ./arcane.svg)
            );
          };
        };
      };

    # Gate the site with `import auth <group>` (Arcane ignores the identity headers)
    _.forward-auth = {
      includes = [ den.aspects.services.oauth2-proxy ];

      settings.group = lib.mkOption {
        type = lib.types.str;
        example = "admins@idm.example.com";
        description = "Group a user needs, as the identity provider sends it";
      };

      nixos =
        { host, ... }:
        {
          virtualisation.quadlet.containers."quadlet-${name}".containerConfig.labels."caddy.import" = "auth ${
            host.settings.services.${name}.forward-auth.group
          }";
        };
    };

    # Key for the credentials Arcane stores (registries, git, variables) from sops. Without it,
    # Arcane falls back to a built-in development key.
    _.encryption-key = {
      includes = [ den.aspects.programs.sops ];

      settings = {
        sopsFile = lib.mkOption {
          type = lib.types.path;
          description = "sops-encrypted file holding the encryption key";
        };
        key = lib.mkOption {
          type = lib.types.str;
          default = "arcane/ENCRYPTION_KEY";
          description = "Key of the encryption key (`base64:` + 32 random bytes) inside `sopsFile`";
        };
      };

      nixos =
        { config, host, ... }:
        let
          cfg = host.settings.services.${name}.encryption-key;
          secret = "${name}/encryption-key";
        in
        {
          sops.secrets.${secret} = {
            inherit (cfg) sopsFile key;
            # Arcane reads it after dropping to its user
            owner = host.settings.services.${name}.user;
            restartUnits = [ unit ];
          };
          virtualisation.quadlet.containers."quadlet-${name}".containerConfig = {
            volumes = [ "${config.sops.secrets.${secret}.path}:/run/secrets/encryption-key:ro" ];
            environments.ENCRYPTION_KEY_FILE = "/run/secrets/encryption-key";
          };
        };
    };

    # Sign in through one OIDC provider, configured here (the settings are then read-only in
    # Arcane's UI): go straight to the provider, and give members of `adminGroup` (from the
    # `groups` claim) Arcane's Admin role. Register the client at the provider with redirect
    # `https://<domain>/auth/oidc/callback`. Local logins stay available for recovery.
    _.sso-login = {
      includes = [ den.aspects.programs.sops ];

      settings = {
        issuerUrl = lib.mkOption {
          type = lib.types.str;
          example = "https://idm.example.com/oauth2/openid/arcane";
          description = "OIDC issuer URL of the client at the provider";
        };
        clientId = lib.mkOption {
          type = lib.types.str;
          default = name;
          description = "OAuth2 client ID at the provider";
        };
        providerName = lib.mkOption {
          type = lib.types.str;
          example = "Kanidm";
          description = "Provider name on the login button";
        };
        adminGroup = lib.mkOption {
          type = lib.types.str;
          example = "admins@idm.example.com";
          description = "`groups` claim value that gets Arcane's Admin role";
        };
        sopsFile = lib.mkOption {
          type = lib.types.path;
          description = "sops-encrypted file holding the client secret";
        };
        key = lib.mkOption {
          type = lib.types.str;
          default = "arcane/OIDC_CLIENT_SECRET";
          description = "Key of the client secret inside `sopsFile`";
        };
      };

      nixos =
        { config, host, ... }:
        let
          cfg = host.settings.services.${name}.sso-login;
          secret = "${name}/oidc-client-secret";
        in
        {
          sops.secrets.${secret} = {
            inherit (cfg) sopsFile key;
            # Arcane reads it after dropping to its user
            owner = host.settings.services.${name}.user;
            restartUnits = [ unit ];
          };
          virtualisation.quadlet.containers."quadlet-${name}".containerConfig = {
            volumes = [ "${config.sops.secrets.${secret}.path}:/run/secrets/oidc-client-secret:ro" ];
            environments = {
              OIDC_ENABLED = "true";
              OIDC_ISSUER_URL = cfg.issuerUrl;
              OIDC_CLIENT_ID = cfg.clientId;
              OIDC_CLIENT_SECRET_FILE = "/run/secrets/oidc-client-secret";
              OIDC_SCOPES = "openid email profile groups";
              OIDC_GROUPS_CLAIM = "groups";
              OIDC_PROVIDER_NAME = cfg.providerName;
              OIDC_AUTO_REDIRECT_TO_PROVIDER = "true";
              OIDC_ROLE_MAPPINGS = builtins.toJSON [
                {
                  claimValue = cfg.adminGroup;
                  roleId = "role_admin";
                }
              ];
            };
          };
        };
    };
  };
}
