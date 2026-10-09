# Kanidm on prts: aspect settings and identity data (services.kanidm provisions it on every start).
# Apps gate on the prts_* groups, never on Kanidm's built-in ones (idm_admins etc. grant Kanidm
# admin rights, not app access). Credentials (passkeys) are not provisioned: enroll them through
# `kanidm person credential create-reset-token <name> -D idm_admin`.
# Removing an entity here deletes it from Kanidm (provision.autoRemove).
{ den, ... }:
{
  den.hosts."x86_64-linux"."prts" = {
    settings.services.kanidm = {
      # Upgrade one release at a time, see the option's description
      version = "1_11";
      domain = "idm.songpola.dev";
      backupDir = "/tank/v2/services/kanidm/backups";
      sopsFile = ./secrets/auth.secrets.yaml;
    };
  };

  den.aspects."prts" = {
    includes = [ den.aspects.services.kanidm ];

    nixos.services.kanidm.provision = {
      groups = {
        prts_admins = { };
        prts_media = { };
      };

      persons.songpola = {
        displayName = "Songpol Anannetikul";
        # oauth2-proxy needs an email claim
        mailAddresses = [ "songpola@songpola.dev" ];
        groups = [
          "prts_admins"
          "prts_media"
        ];
      };
    };
  };
}
