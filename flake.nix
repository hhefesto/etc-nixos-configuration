{
  description = "hhefesto's system configuration";

  inputs.nix.url = "github:nixos/nix/master";
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  inputs.devenv.url = "github:cachix/devenv/latest";

  outputs = inputs@{ self, nixpkgs, devenv, ... }:
  {
    nixosConfigurations.olimpo = nixpkgs.lib.nixosSystem {
      # inherit system;
      system = "x86_64-linux";
      # modules = [ ./configuration.nix { self1 = self; nixpkgs = nixpkgs; } ];
      modules = [ (import ./configuration.nix) ];
      specialArgs = { inherit inputs; };
    };

  };
}
