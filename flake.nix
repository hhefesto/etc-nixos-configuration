{
  description = "hhefesto's darwin system configuration";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-22.05-darwin";
  inputs.darwin.url = "github:lnl7/nix-darwin/master";
  inputs.darwin.inputs.nixpkgs.follows = "nixpkgs";

  outputs = inputs@{ self, darwin, nixpkgs, ... }:
  {
    darwinConfigurations.olimpo = darwin.lib.darwinSystem {
      system = "x86_64-darwin";
      modules = [ ./darwin-configuration.nix
      	      	];
      specialArgs = { inherit inputs; };
    };

  };
}