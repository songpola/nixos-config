{_lib}: {
  settings = {
    substituters = [
      "http://prts:5000/"
    ];
    trusted-public-keys = [
      _lib.public.harmonia
    ];
  };
}
