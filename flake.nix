{
  description = "hhefesto's system configuration";

  inputs.determinate.url = "https://flakehub.com/f/DeterminateSystems/determinate/*";
  inputs.nixpkgs.url = "https://flakehub.com/f/NixOS/nixpkgs/*";
  inputs.home-manager.url = "github:nix-community/home-manager";
  inputs.home-manager.inputs.nixpkgs.follows = "nixpkgs";
  inputs.tontine-system.url = "git+ssh://git@github.com/TontineTrust/raDeploy.git";
  inputs.agenix = {
    url = "github:ryantm/agenix";
    inputs.nixpkgs.follows = "nixpkgs";
  };


  outputs = inputs@{ self, determinate, nixpkgs, home-manager, tontine-system, ... }:
  let
    system = "x86_64-linux";
    pkgs = nixpkgs.legacyPackages.${system};
    myAgda = pkgs.agda.withPackages (p: [ p.standard-library p.agda-categories ]);
  in {
    # Your original configuration
    nixosConfigurations.olimpo = nixpkgs.lib.nixosSystem {
      inherit system;
      modules = [ ./configuration.nix
                  # determinate.nixosModules.default
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

    # Combined configuration with server services
    nixosConfigurations.olimpo-work = nixpkgs.lib.nixosSystem {
      inherit system;
      modules = [
        ./configuration.nix
        home-manager.nixosModules.home-manager
        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.users.hhefesto = import ./home.nix;
          home-manager.extraSpecialArgs = { inherit myAgda; };
        }

        # Add server services from tontine-system
        tontine-system.nixosModules.admin
        tontine-system.nixosModules.services
        tontine-system.nixosModules.db
      ];
      specialArgs = {
        inherit inputs myAgda;
        # Pass the server flake inputs that the modules might need
        inherit (tontine-system.inputs) robo-actuary raDB raDash;
        deploymentEnvironment = "dev";
      };
    };
  };
}
