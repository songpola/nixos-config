{ pkgs, ... }:
{
  # Node.js Development Environment
  environment.systemPackages = with pkgs; [
    nodejs
    corepack
    bun
  ];
}
