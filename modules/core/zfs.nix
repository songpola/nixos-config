{ den, lib, ... }:
{
  # Hosts opt in with `zfs.enable = true;`.
  den.schema.host.imports = [
    {
      options.zfs = {
        enable = lib.mkEnableOption "ZFS support (includes the zfs aspect)";
        hostId = lib.mkOption {
          type = lib.types.nullOr (lib.types.strMatching "[0-9a-f]{8}");
          default = null;
          description = "networking.hostId; ZFS refuses to import pools without a unique 8-hex-digit ID (required when enabled)";
        };
        extraPools = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [ ];
          description = "Pools to import after boot (boot.zfs.extraPools)";
        };
      };
    }
  ];

  den.policies.zfs-on-host =
    { host, ... }:
    lib.optional (host.class == "nixos" && host.zfs.enable) (den.lib.policy.include den.aspects.zfs);
  den.schema.host.includes = [ den.policies.zfs-on-host ];

  den.aspects.zfs.nixos =
    { host, ... }:
    let
      cfg = host.zfs;
    in
    {
      assertions = [
        {
          assertion = cfg.hostId != null;
          message = "zfs.hostId must be set on host ${host.name} when zfs.enable is true";
        }
      ];

      networking.hostId = cfg.hostId;

      boot.supportedFilesystems = [ "zfs" ];

      boot.zfs = {
        inherit (cfg) extraPools;

        devNodes = "/dev/disk/by-id";

        # Forcibly import the ZFS root pool(s) during early boot.
        #
        # This is enabled by default for backwards compatibility purposes,
        # but it is HIGHLY RECOMMENDED to DISABLE this option,
        # as it bypasses some of the safeguards ZFS uses to protect your ZFS pools.
        #
        # If you set this option to false and NixOS subsequently fails to boot because it cannot import the root pool,
        # you should boot with the zfs_force=1 option as a kernel parameter (e.g. by manually editing the kernel params in grub during boot).
        # You should only need to do this once.
        forceImportRoot = false;
      };

      services.zfs = {
        autoScrub.enable = true;
        trim.enable = true;
      };
    };
}
