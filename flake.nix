{
  description = "hhefesto's system configurations";

  inputs = {
    determinate.url = "https://flakehub.com/f/DeterminateSystems/determinate/*";
    nixpkgs.url = "https://flakehub.com/f/NixOS/nixpkgs/*";
    flake-parts.url = "github:hercules-ci/flake-parts";
    deploy-rs = {
      url = "github:serokell/deploy-rs";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    home-manager = {
      url = "github:nix-community/home-manager/release-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    agenix = {
      url = "github:ryantm/agenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    expedientes.url = "git+file:///home/hhefesto/src/expedientes";
    cfo-as-a-service.url = "path:/home/hhefesto/src/cfo-as-a-service";
    wedding-page.url = "path:/home/hhefesto/src/wedding-website";
    claude-code-nix.url = "github:sadjow/claude-code-nix";
    opencode.url = "github:anomalyco/opencode";
    spacemacs = {
      url = "github:syl20bnr/spacemacs";
      flake = false;
    };
  };

  outputs = inputs@{ self, flake-parts, nixpkgs, home-manager, deploy-rs, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [ "x86_64-linux" ];

      flake = let
        system = "x86_64-linux";

        home-manager-module = { xmobarrc }: {
          imports = [ home-manager.nixosModules.home-manager ];
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.users.hhefesto = import ./home.nix;
          home-manager.extraSpecialArgs = {
            spacemacs = inputs.spacemacs;
            inherit xmobarrc;
          };
        };

        cfo = (import "${inputs."cfo-as-a-service"}/nixosModules/cfo-as-a-service.nix") null;

        expedientesModule = { ports, databaseName, startingBackup ? null }:
          (import "${inputs.expedientes}/nixosModules/expedientes.nix") {
            inherit ports databaseName startingBackup;
            packages = {
              backend        = inputs.expedientes.packages.${system}.expedientes-backend;
              frontendStatic = inputs.expedientes.packages.${system}.expedientes-frontend-static;
            };
          };

        expedientesOlimpo = expedientesModule {
          ports        = { nginx = 80; backend = 3000; database = 5432; };
          databaseName = "expedientes";
          startingBackup = {
            dump = "/home/hhefesto/.local/share/expedientes/restore/var/lib/expedientes-backup/staging/expedientes.dump";
            html = "/home/hhefesto/.local/share/expedientes/restore/html";
          };
        };
        expedientesDelfos = expedientesModule {
          ports        = { nginx = 80; backend = 3000; database = 5432; };
          databaseName = "expedientes";
        };
        expedientesXty = expedientesModule {
          ports        = { nginx = 80; backend = 3000; database = 5432; };
          databaseName = "expedientes";
        };

        mkHost = { hostModules, extraSpecialArgs ? {} }: nixpkgs.lib.nixosSystem {
          inherit system;
          modules = hostModules;
          specialArgs = { inherit inputs; } // extraSpecialArgs;
        };
      in {
        nixosConfigurations.delfos = mkHost {
          hostModules = [
            ./delfos.nix
            ./projects-desktop.nix
            ./configuration.nix
            ./configuration-gui.nix
            inputs.agenix.nixosModules.default
            cfo
            expedientesDelfos
            (home-manager-module { xmobarrc = ./xmobarrc-delfos; })
          ];
          extraSpecialArgs = { xmonadShortenLength = 26; };
        };

        nixosConfigurations.olimpo = mkHost {
          hostModules = [
            ./olimpo.nix
            ./projects-desktop.nix
            ./configuration.nix
            ./configuration-gui.nix
            inputs.agenix.nixosModules.default
            cfo
            expedientesOlimpo
            (home-manager-module { xmobarrc = ./xmobarrc-olimpo; })
          ];
          extraSpecialArgs = { xmonadShortenLength = 50; };
        };

        nixosConfigurations.xty = mkHost {
          hostModules = [
            ./xty.nix
            ./projects-xty.nix
            ./configuration.nix
            cfo
            expedientesXty
          ];
        };

        deploy.nodes.xty = {
          hostname = "62.238.6.4";
          profiles.system = {
            sshUser = "root";
            path = deploy-rs.lib.${system}.activate.nixos self.nixosConfigurations.xty;
          };
        };
      };

      perSystem = { pkgs, ... }: {
        packages = let
          hosts = self.nixosConfigurations;
          entries = builtins.map (name: {
            inherit name;
            path = hosts.${name}.config.system.build.toplevel;
          }) (builtins.attrNames hosts);
        in {
          default = pkgs.linkFarm "all-hosts" entries;
          delfos = hosts.delfos.config.system.build.toplevel;
          olimpo = hosts.olimpo.config.system.build.toplevel;
          xty = hosts.xty.config.system.build.toplevel;
        };
      };
    };
}
