{
  description = "hhefesto's system configuration";

  # inputs.nix.url = "github:nixos/nix/master";
  inputs.determinate.url = "https://flakehub.com/f/DeterminateSystems/determinate/*";
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  # inputs.nixpkgs.url = "https://flakehub.com/f/NixOS/nixpkgs/*";
  inputs.home-manager.url = "github:nix-community/home-manager";
  inputs.home-manager.inputs.nixpkgs.follows = "nixpkgs";
  inputs.agenix = {
    url = "github:ryantm/agenix";
    inputs.nixpkgs.follows = "nixpkgs";
  };


  outputs = inputs@{ self, determinate, nixpkgs, home-manager, ... }:
  let
    system = "x86_64-linux";
    pkgs = nixpkgs.legacyPackages.${system};
    myAgda = pkgs.agda.withPackages (p: [ p.standard-library p.agda-categories ]);
  in {
    nixosConfigurations = {
      delfos = nixpkgs.lib.nixosSystem {
        inherit system;

        modules = [ # determinate.nixosModules.default
                    # ./delfos.nix
                    ./configuration.nix
                    home-manager.nixosModules.home-manager
                    {
                      home-manager.useGlobalPkgs = true;
                      home-manager.useUserPackages = true;
                      home-manager.users.hhefesto = import ./home.nix;
                      # home-manager.users.moper = import ./home-moper.nix;
                      home-manager.extraSpecialArgs = { inherit myAgda; };
                    }
                  ];
        specialArgs = { inherit inputs myAgda; };
      };
      olimpo = nixpkgs.lib.nixosSystem {
        inherit system;

        modules = [ # determinate.nixosModules.default
                    ./olimpo.nix
                    ./configuration.nix
                    home-manager.nixosModules.home-manager
                    {
                      home-manager.useGlobalPkgs = true;
                      home-manager.useUserPackages = true;
                      home-manager.users.hhefesto = import ./home.nix;
                      home-manager.users.moper = import ./home-moper.nix;
                      home-manager.extraSpecialArgs = { inherit myAgda; };
                    }
                  ];
        specialArgs = { inherit inputs myAgda; };
      };
    };

    packages.${system}.default = self.nixosConfigurations.delfos.config.system.build.toplevel;
  };
}
