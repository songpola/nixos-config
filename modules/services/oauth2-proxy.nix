# oauth2-proxy as the forward-auth gate for services.caddy-reverse-proxy (https://oauth2-proxy.github.io)
# Runs as a NixOS oci-containers unit on the proxy network, serving its login flow at
# settings.domain; Caddy asks it about every request to a gated site (`/oauth2/auth`).
# Sign-in is OIDC (authorization code + PKCE S256) against a provider such as services.kanidm,
# where the client is registered separately; the client secret is shared with it through
# `meta.clientSecret`. The session cookie covers settings.cookieDomain, so one login spans all
# gated sites.
#
# Sites opt in through the `auth` snippet, with the group a user needs (as the provider sends it),
# e.g. in a compose stack:
#   labels:
#     caddy: app.example.com
#     caddy.import: auth admins@idm.example.com
#     caddy.reverse_proxy: "{{upstreams 8080}}"
# Gated apps get the user from the X-Auth-Request-{User,Email,Groups,Preferred-Username} headers
# (`meta.headers`); client-supplied ones are replaced. Never publish a gated app's port: that
# skips the gate.
{ den, lib, ... }:
let
  name = "oauth2-proxy";
  unit = "podman-${name}.service";
  # oauth2-proxy's HTTP port inside the container
  containerPort = 4180;
  clientSecret = "${name}/client-secret";
  cookieSecret = "${name}/cookie-secret";
  # Identity headers Caddy passes on to gated apps (`--set-xauthrequest`)
  headers = {
    user = "X-Auth-Request-User"; # the OIDC `sub` (a UUID with Kanidm)
    email = "X-Auth-Request-Email";
    groups = "X-Auth-Request-Groups"; # comma-separated
    preferredUsername = "X-Auth-Request-Preferred-Username";
  };
in
{
  den.aspects.services.${name} = {
    includes = [
      den.aspects.programs.sops
      den.aspects.services.caddy-reverse-proxy
    ];

    # For the identity provider's copy of the client secret (e.g. Kanidm's `basicSecretFile`)
    meta.clientSecret = clientSecret;
    # For gated apps that read the user from headers (e.g. services.dozzle.forward-auth)
    meta.headers = headers;

    settings = {
      domain = lib.mkOption {
        type = lib.types.str;
        example = "auth.example.com";
        description = "Domain oauth2-proxy is served at (login flow and callback)";
      };
      cookieDomain = lib.mkOption {
        type = lib.types.str;
        example = ".example.com";
        description = ''
          Domain of the session cookie, covering every gated site;
          also the only allowed target of post-login redirects.
        '';
      };
      oidcIssuerUrl = lib.mkOption {
        type = lib.types.str;
        example = "https://idm.example.com/oauth2/openid/oauth2-proxy";
        description = "OIDC issuer URL of the client at the identity provider";
      };
      clientId = lib.mkOption {
        type = lib.types.str;
        default = name;
        description = "OAuth2 client ID at the identity provider";
      };
      sopsFile = lib.mkOption {
        type = lib.types.path;
        description = "sops-encrypted file holding the client secret and the cookie secret";
      };
      clientSecretKey = lib.mkOption {
        type = lib.types.str;
        default = "oauth2-proxy/CLIENT_SECRET";
        description = "Key of the OAuth2 client secret inside `sopsFile`";
      };
      cookieSecretKey = lib.mkOption {
        type = lib.types.str;
        default = "oauth2-proxy/COOKIE_SECRET";
        description = "Key of the cookie secret (16, 24 or 32 bytes) inside `sopsFile`";
      };
      image = lib.mkOption {
        type = lib.types.str;
        default = "quay.io/oauth2-proxy/oauth2-proxy:latest";
        description = "oauth2-proxy image";
      };
    };

    nixos =
      { config, host, ... }:
      let
        cfg = host.settings.services.${name};
        caddy = host.settings.services.caddy-reverse-proxy;
      in
      {
        sops.secrets = {
          ${clientSecret} = {
            inherit (cfg) sopsFile;
            key = cfg.clientSecretKey;
          };
          ${cookieSecret} = {
            inherit (cfg) sopsFile;
            key = cfg.cookieSecretKey;
          };
        };
        sops.templates."${name}.env" = {
          content = ''
            OAUTH2_PROXY_CLIENT_SECRET=${config.sops.placeholder.${clientSecret}}
            OAUTH2_PROXY_COOKIE_SECRET=${config.sops.placeholder.${cookieSecret}}
          '';
          restartUnits = [ unit ];
        };

        systemd.services."podman-${name}" = rec {
          wants = [ "podman-network-${caddy.network}.service" ];
          after = wants;
        };

        virtualisation.oci-containers.containers.${name} = {
          inherit (cfg) image;
          networks = [ caddy.network ];
          environmentFiles = [ config.sops.templates."${name}.env".path ];
          environment = {
            OAUTH2_PROXY_HTTP_ADDRESS = "0.0.0.0:${toString containerPort}";
            # Behind Caddy: trust X-Forwarded-*; answer /oauth2/auth only, no upstream to proxy
            OAUTH2_PROXY_REVERSE_PROXY = "true";
            OAUTH2_PROXY_UPSTREAMS = "static://202";

            OAUTH2_PROXY_PROVIDER = "oidc";
            OAUTH2_PROXY_OIDC_ISSUER_URL = cfg.oidcIssuerUrl;
            OAUTH2_PROXY_CLIENT_ID = cfg.clientId;
            OAUTH2_PROXY_CODE_CHALLENGE_METHOD = "S256";
            OAUTH2_PROXY_SCOPE = "openid email profile groups";
            OAUTH2_PROXY_REDIRECT_URL = "https://${cfg.domain}/oauth2/callback";
            OAUTH2_PROXY_SKIP_PROVIDER_BUTTON = "true";
            # Access is decided by groups (the snippet's argument), not by email domain
            OAUTH2_PROXY_EMAIL_DOMAINS = "*";

            OAUTH2_PROXY_COOKIE_DOMAINS = cfg.cookieDomain;
            OAUTH2_PROXY_WHITELIST_DOMAINS = cfg.cookieDomain;
            OAUTH2_PROXY_COOKIE_SECURE = "true";

            # Identity headers on /oauth2/auth responses, for Caddy to copy to the app
            OAUTH2_PROXY_SET_XAUTHREQUEST = "true";
            # Caddy checks every request to a gated site there (polling UIs log a line every few
            # seconds); sign-in/out stays logged, denials (403 without the group) don't
            OAUTH2_PROXY_EXCLUDE_LOGGING_PATHS = "/oauth2/auth";
          };
          labels = den.aspects.programs.podman.meta.autoUpdateLabels // {
            "caddy" = cfg.domain;
            "caddy.reverse_proxy" = "{{upstreams ${toString containerPort}}}";
            # Not bundled with Dozzle; selfh.st icon (CC BY 4.0, https://selfh.st/icons)
            "dev.dozzle.icon" = "data:image/svg+xml," + lib.escapeURL (builtins.readFile ./oauth2-proxy.svg);
          };
        };
      };

    # `import auth <group>`: ask oauth2-proxy, send users without a session to the login flow (401),
    # and pass the identity headers on to the app. copy_headers replaces client-supplied copies
    # (deleted, then set from the auth response); a separate request_header would run after
    # forward_auth and delete the real ones. oauth2-proxy answers 403 when the user lacks the group.
    caddy-snippets =
      { host, ... }:
      let
        cfg = host.settings.services.${name};
      in
      ''
        (auth) {
          forward_auth ${name}:${toString containerPort} {
            uri /oauth2/auth?allowed_groups={args[0]}
            copy_headers ${lib.concatStringsSep " " (lib.attrValues headers)}
            @unauthenticated status 401
            handle_response @unauthenticated {
              redir * https://${cfg.domain}/oauth2/start?rd={scheme}://{host}{uri}
            }
          }
        }
      '';
  };
}
