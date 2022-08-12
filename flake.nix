{
  description = "hhefesto's system configuration";

  # inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-20.03";
  inputs.nix.url = "github:nixos/nix/master";
  # inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-21.11";
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  # inputs.unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
  inputs.nixos-hardware.url = github:NixOS/nixos-hardware/master;

  outputs = inputs@{ self, nixpkgs, nixos-hardware, ... }:
  {
    nixosConfigurations.olimpo = nixpkgs.lib.nixosSystem {
      # inherit system;
      system = "x86_64-linux";
      # modules = [ ./configuration.nix { self1 = self; nixpkgs = nixpkgs; } ];
      modules = [ (import ./configuration.nix)
       	      	# nixos-hardware.nixosModules.dell-xps-15-9560-nvidia
      	      	];
      specialArgs = { inherit inputs; };
    };

  };
}
