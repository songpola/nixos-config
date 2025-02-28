{
  # # https://snowfall.org/guides/lib/library/
  # # This is the merged library containing your namespaced library as well as all libraries from
  # # your flake's inputs.
  # lib,
  # # Your flake inputs are also available.
  # inputs,
  # # The namespace used for your flake, defaulting to "internal" if not set.
  # namespace,
  # # Additionally, Snowfall Lib's own inputs are passed. You probably don't need to use this!
  # snowfall-inputs,
}: {
  public = {
    ssh = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMSjfctCxjS+/jDcVERwcTN6wP+GaScfSo4VtfsmagOz songpola";
    harmonia = "prts-1:SDYZAeLQIUUHEasfmPNUFtnFgW+q2LiwX0+dOvPerbk=";
  };
}
