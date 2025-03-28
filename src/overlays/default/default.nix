# https://snowfall.org/guides/lib/overlays/
# Snowfall Lib provides access to additional information via a primary argument of
# your overlay.
{
  # # Channels are named after NixPkgs instances in your flake inputs. For example,
  # # with the input `nixpkgs` there will be a channel available at `channels.nixpkgs`.
  # # These channels are system-specific instances of NixPkgs that can be used to quickly
  # # pull packages into your overlay.
  channels,
  # # The namespace used for your Flake, defaulting to "internal" if not set.
  # namespace,
  # # Inputs from your flake.
  inputs,
  ...
}: final: prev: {
  inherit (channels.unstable) tailscale;

  btop = prev.btop.override {
    cudaSupport = true;
  };
}
