{
  lib,
  config,
  _lib,
}: {
  age.keyFile = config.home.homeDirectory + "/.config/sops/age/keys.txt";
  defaultSopsFile = _lib.secrets;

  secrets = {
    example-key = {};
    # "myservice/my_subdir/my_secret" = {
    #   owner = "sometestservice";
    # };
  };
}
