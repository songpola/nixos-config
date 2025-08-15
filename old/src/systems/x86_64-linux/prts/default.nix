{
  imports = [
    # Containers
    ./containers/immich.nix
    ./containers/n8n.nix
    ./containers/firefly-iii.nix
    ./containers/kimai.nix
    ./containers/vikunja.nix

    # NOTE: Too buggy: Event time incorrect with CalDav
    # ./containers/fluid-calendar.nix
  ];
}
