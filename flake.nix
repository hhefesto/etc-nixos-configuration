{
  description = "hhefesto's system configuration";

  inputs.nix.url = "github:nixos/nix/master";
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  inputs.home-manager.url = "github:nix-community/home-manager";
  inputs.home-manager.inputs.nixpkgs.follows = "nixpkgs";

  outputs = inputs@{ self, nix, nixpkgs, home-manager, ... }:
  {
    nixosConfigurations.olimpo = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [ ./configuration.nix
                  home-manager.nixosModules.home-manager
                  {
                    home-manager.useGlobalPkgs = true;
                    home-manager.useUserPackages = true;
                    home-manager.users.hhefesto = import ./home.nix;

                    # Optionally, use home-manager.extraSpecialArgs to pass
                    # arguments to home.nix
                  }

                ];
      specialArgs = { inherit inputs; };
    };

  };
}
