{
  # SMART monitoring of every disk smartd finds. Warnings go to the journal and wall
  # (no mail is set up).
  den.aspects.services.smartd.nixos.services.smartd = {
    enable = true;
    # All attributes, automatic offline data collection; short self-test daily at 02:00,
    # long one monthly on the second Saturday at 03:00. A long test reads the whole disk (hours
    # on large HDDs), so it stays apart from the monthly ZFS scrub on the 1st.
    defaults.monitored = "-a -o on -s (S/../.././02|L/../(0[8-9]|1[0-4])/6/03)";
  };
}
