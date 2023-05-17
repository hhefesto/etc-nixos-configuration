{
  description = "hhefesto's system configuration";

  inputs.nix.url = "github:nixos/nix/master";
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  inputs.home-manager.url = "github:nix-community/home-manager";
  inputs.home-manager.inputs.nixpkgs.follows = "nixpkgs";
  inputs.nixos-hardware.url = github:NixOS/nixos-hardware/master;

  outputs = inputs@{ self, nixpkgs, nixos-hardware, ... }:
  {
    nixosConfigurations.olimpo = nixpkgs.lib.nixosSystem {
      # inherit system;
      system = "x86_64-linux";
      # modules = [ ./configuration.nix { self1 = self; nixpkgs = nixpkgs; } ];
      modules = [ (import ./configuration.nix)
                  # home-manager.nixosModules.home-manager
                  # {
                  #   home-manager.useGlobalPkgs = true;
                  #   home-manager.useUserPackages = true;
                  #   home-manager.users.jdoe = import ./home.nix;

                  #   # Optionally, use home-manager.extraSpecialArgs to pass
                  #   # arguments to home.nix
                  # }

       	      	# nixos-hardware.nixosModules.dell-xps-15-9560-nvidia
      	      	];
      specialArgs = { inherit inputs; };
    };

  };
}
