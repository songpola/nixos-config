# Kanidm identity provider (users, groups, passkeys, OIDC), run natively on the host.
# Serves TLS itself with its own ACME certificate (DNS-01 via Cloudflare), issued for exactly
# `settings.domain`: Kanidm advises against wildcard or shared certificates.
# Exposed through services.caddy-reverse-proxy (a `caddy-sites` entry), which verifies that
# certificate; the proxy reaches the host through host.containers.internal, so the firewall opens
# the port to podman bridges. The certificate uses the `security.acme-cloudflare` account.
{ den, lib, ... }:
let
  name = "kanidm";
in
{
  den.aspects.services.${name} = {
    includes = [
      den.aspects.services.caddy-reverse-proxy
      den.aspects.security.acme-cloudflare
    ];

    settings = {
      version = lib.mkOption {
        type = lib.types.str;
        example = "1_11";
        description = ''
          Kanidm release, as in nixpkgs' `kanidm_<version>`; there is no unversioned alias.
          Kanidm can only be upgraded to the adjacent release (each one migrates the database),
          and nixpkgs marks a release vulnerable 30 days after its successor ships.
          Bump it one release at a time.
        '';
      };
      domain = lib.mkOption {
        type = lib.types.str;
        example = "idm.example.com";
        description = ''
          Domain Kanidm is served at. Passkeys are bound to it, so never change it
          (changing it needs extra steps, see Kanidm's domain rename docs).
        '';
      };
      port = lib.mkOption {
        type = lib.types.port;
        default = 8443;
        description = "Port Kanidm listens on (HTTPS)";
      };
      backupDir = lib.mkOption {
        type = lib.types.str;
        default = "/var/lib/kanidm/backups";
        description = "Directory for online backups, e.g. on a dataset with snapshots";
      };
      backupVersions = lib.mkOption {
        type = lib.types.ints.unsigned;
        default = 7;
        description = "Number of daily online backups to keep (0 disables them)";
      };
    };

    nixos =
      {
        config,
        pkgs,
        host,
        ...
      }:
      let
        cfg = host.settings.services.${name};
        port = toString cfg.port;
        certDir = config.security.acme.certs.${cfg.domain}.directory;
        hasZfs = config.boot.zfs.enabled;
      in
      {
        assertions = [
          {
            assertion = config.virtualisation.oci-containers.containers ? caddy-reverse-proxy;
            message = "services.kanidm needs the services.caddy-reverse-proxy aspect.";
          }
        ];

        services.kanidm = {
          package = pkgs."kanidmWithSecretProvisioning_${cfg.version}";
          server = {
            enable = true;
            settings = {
              inherit (cfg) domain;
              origin = "https://${cfg.domain}";
              bindaddress = "0.0.0.0:${port}";
              tls_chain = "${certDir}/fullchain.pem";
              tls_key = "${certDir}/key.pem";
              online_backup = {
                path = cfg.backupDir;
                versions = cfg.backupVersions;
              };
            };
          };
        };

        # DNS provider, credentials and email come from `security.acme.defaults`
        security.acme.certs.${cfg.domain} = {
          group = "kanidm";
          # Kanidm only reads the certificate at startup
          reloadServices = [ "kanidm.service" ];
        };

        systemd.services.kanidm = rec {
          wants = [ "acme-${cfg.domain}.service" ];
          # Only the backup directory may live on ZFS, so order after the mount without requiring
          # it: the database is on the root disk and login should survive a failed pool import.
          after = wants ++ lib.optional hasZfs "zfs-mount.service";
        };

        # The proxy container reaches Kanidm through the bridge gateway (host.containers.internal);
        # the bridge names are dynamic (podman0, podman1, ...).
        networking.firewall.extraInputRules = lib.mkIf config.networking.nftables.enable ''
          iifname "podman*" tcp dport ${port} accept comment "kanidm from podman bridges"
        '';
        networking.firewall.extraCommands = lib.mkIf (!config.networking.nftables.enable) ''
          iptables -A nixos-fw -i podman+ -p tcp --dport ${port} -j nixos-fw-accept
        '';
      };

    # The proxy serves Kanidm's domain, and containers on the proxy network reach it through
    # the proxy (a network alias), not via the host's Tailscale address.
    caddy-sites =
      { host, ... }:
      let
        cfg = host.settings.services.${name};
      in
      {
        inherit (cfg) domain;
        upstream = "https://host.containers.internal:${toString cfg.port}";
        reverseProxy = {
          transport = "http";
          "transport.tls_server_name" = cfg.domain;
        };
      };
  };
}
