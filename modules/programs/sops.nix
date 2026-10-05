{ inputs, ... }:
{
  flake-file.inputs.sops-nix = {
    url = "github:Mic92/sops-nix";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  # Secrets are decrypted with the host's SSH ed25519 key (sops-nix's default with openssh);
  # its age recipient is listed in /.sops.yaml. Edit with `just sops-edit <file>`.
  den.aspects.programs.sops.nixos = {
    imports = [ inputs.sops-nix.nixosModules.default ];
  };
}
