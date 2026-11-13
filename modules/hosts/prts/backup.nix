# prts backups: sanoid snapshots `tank`, syncoid replicates it to the `backup` pool.
#
# `backup` is a single 2 TB SMR disk (Seagate ST2000DM005), created by hand:
#
#   zpool create -o ashift=12 -O compression=zstd -O atime=off -O xattr=sa \
#     -O acltype=posix -O mountpoint=none -O readonly=on \
#     backup /dev/disk/by-id/ata-ST2000DM005-2U9102_WFM449L2
#
# `mountpoint=none` is inherited by everything received (syncoid sends no properties),
# so the copies never mount over `/tank`, and the unprivileged syncoid user never has to
# mount anything. `readonly=on` keeps the copies from diverging from their source.
let
  # Not backed up: the arrs' media and torrents, re-downloadable and too big for `backup`.
  excluded = [
    "tank/v2/arrs-data"
  ];
in
{
  den.aspects."prts".nixos =
    { lib, ... }:
    {
      services.sanoid = {
        enable = true;

        # A template is a named set of retention rules that datasets use.
        #
        # Each side prunes on its own schedule, which is safe: syncoid only needs one
        # snapshot both sides still have to send the changes since then. Normally
        # that's the latest hourly one; if replication stopped for weeks, the
        # monthly snapshots would still give it one in common.
        templates = {
          # The live data on `tank`.
          source = {
            # Roll back to any hour of the last day, any day of the last two weeks,
            # or any month of the last quarter.
            hourly = 24;
            daily = 14;
            monthly = 3;
            # sanoid takes the snapshots (its timer runs hourly).
            autosnap = true;
            # and deletes the ones past the limits above.
            autoprune = true;
          };
          # The copies on `backup/tank`.
          replica = {
            hourly = 24;
            # More history than the source: a year on the backup, a quarter on `tank`.
            daily = 30;
            monthly = 12;
            # No snapshots taken here: syncoid brings `tank`'s along with the data.
            autosnap = false;
            # sanoid only deletes old ones, by the limits above.
            autoprune = true;
          };
        };

        datasets = {
          # Children inherit `tank`'s settings and override them below; sanoid reads
          # the sections in file order (sorted, so parents first).
          "tank" = {
            useTemplate = [ "source" ];
            recursive = true;
          };
          "backup/tank" = {
            useTemplate = [ "replica" ];
            recursive = true;
          };
        }
        // lib.genAttrs excluded (_: {
          autosnap = false;
          autoprune = false;
          recursive = true;
        });
      };

      services.syncoid = {
        enable = true;
        # Hourly by default, so the copy is at most an hour behind.
        commands."tank" = {
          source = "tank";
          target = "backup/tank";
          recursive = true;
          extraArgs = [
            # Replicate sanoid's snapshots instead of making syncoid's own.
            "--no-sync-snap"
          ]
          ++ map (d: "--exclude-datasets=^${d}(/|$)") excluded;
          # Without sync snapshots, the source needs only these.
          localSourceAllow = [
            "bookmark"
            "hold"
            "send"
          ];
        };
      };
    };
}
