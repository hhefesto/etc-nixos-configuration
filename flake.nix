{
  description = "hhefesto's system configuration";

  inputs.determinate.url = "https://flakehub.com/f/DeterminateSystems/determinate/*";
  inputs.nixpkgs.url = "https://flakehub.com/f/NixOS/nixpkgs/*";
  inputs.home-manager.url = "github:nix-community/home-manager";
  inputs.home-manager.inputs.nixpkgs.follows = "nixpkgs";
  inputs.agenix = {
    url = "github:ryantm/agenix";
    inputs.nixpkgs.follows = "nixpkgs";
  };
  inputs.claude-code-nix.url = "github:sadjow/claude-code-nix";
  inputs.spacemacs = {
    url = "github:syl20bnr/spacemacs";
    flake = false;
  };


  outputs = inputs@{ self, determinate, nixpkgs, home-manager, claude-code-nix, ... }:
  let
    system = "x86_64-linux";
    pkgs = nixpkgs.legacyPackages.${system};
  in {
    nixosConfigurations.olimpo = nixpkgs.lib.nixosSystem {
      inherit system;
      modules = [ ./configuration.nix
                  # determinate.nixosModules.default
                  home-manager.nixosModules.home-manager
                  {
                    home-manager.useGlobalPkgs = true;
                    home-manager.useUserPackages = true;
                    home-manager.users.hhefesto = import ./home.nix;
                    home-manager.extraSpecialArgs = { spacemacs = inputs.spacemacs; };
                  }
                  {
                    nixpkgs.overlays = [ claude-code-nix.overlays.default ];
                  }
                ];
      specialArgs = { inherit inputs; };
    };

  };
}
