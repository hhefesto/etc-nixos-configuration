{
  description = "hhefesto's system configuration";

  inputs.nix.url = "github:nixos/nix/master";
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  inputs.home-manager.url = "github:nix-community/home-manager";
  inputs.home-manager.inputs.nixpkgs.follows = "nixpkgs";

  outputs = inputs@{ self, nix, nixpkgs, home-manager, ... }:
  let
    system = "x86_64-linux";
    pkgs = nixpkgs.legacyPackages.${system};
    myAgda = pkgs.agda.withPackages (p: [ p.standard-library p.agda-categories ]);
  in {
    nixosConfigurations.delfos = nixpkgs.lib.nixosSystem {
      inherit system;
      modules = [ ./configuration.nix
                  home-manager.nixosModules.home-manager
                  {
                    home-manager.useGlobalPkgs = true;
                    home-manager.useUserPackages = true;
                    home-manager.users.hhefesto = import ./home.nix;
                    home-manager.extraSpecialArgs = { inherit myAgda; };
                  }

                ];
      specialArgs = { inherit inputs myAgda; };
    };
  };
}
