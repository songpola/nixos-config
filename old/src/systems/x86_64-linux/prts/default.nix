{
  imports = [
    # Containers
    ./containers/firefly-iii.nix
    ./containers/kimai.nix

    # NOTE: Too buggy: Event time incorrect with CalDav
    # ./containers/fluid-calendar.nix
  ];
}
