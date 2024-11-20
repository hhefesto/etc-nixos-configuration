{
  description = "hhefesto's system configuration";

  inputs.nix.url = "github:nixos/nix/master";
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs = inputs@{ self, nixpkgs, ... }:
  {
    nixosConfigurations.delfos = nixpkgs.lib.nixosSystem {
      # inherit system;
      system = "x86_64-linux";
      # modules = [ ./configuration.nix { self1 = self; nixpkgs = nixpkgs; } ];
      modules = [ (import ./configuration.nix) ];
      specialArgs = { inherit inputs; };
    };

  };
}
