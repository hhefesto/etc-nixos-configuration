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
    expedientes.url = "git+ssh://git@github.com/hhefesto/docxty";
    cfo-as-a-service.url = "git+ssh://git@github.com/hhefesto/cfo-as-a-service";
    wedding-page.url = "github:hhefesto/wedding-website";
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

        expedientesModule = { ports, databaseName, startingBackup ? null, htmlDir ? "/var/lib/expedientes/html", serverName ? "_" }:
          (import "${inputs.expedientes}/nixosModules/expedientes.nix") {
            inherit ports databaseName startingBackup htmlDir serverName;
            packages = {
              backend        = inputs.expedientes.packages.${system}.expedientes-backend;
              frontendStatic = inputs.expedientes.packages.${system}.expedientes-frontend-static;
            };
          };

        expedientesOlimpo = expedientesModule {
          ports        = { nginx = 80; backend = 3000; database = 5432; };
          databaseName = "expedientes";
          htmlDir      = null;
          startingBackup = {
            dump = "/home/hhefesto/.local/share/expedientes/restore/var/lib/expedientes-backup/staging/expedientes.dump";
          };
        };
        expedientesDelfos = expedientesModule {
          ports        = { nginx = 80; backend = 3000; database = 5432; };
          databaseName = "expedientes";
        };
        expedientesXty = expedientesModule {
          ports        = { nginx = 80; backend = 3000; database = 5432; };
          databaseName = "expedientes";
          serverName   = "docxty.net";
          htmlDir      = null;
          startingBackup = {
            dump = "/var/lib/expedientes-bootstrap/expedientes.dump";
          };
        };

        weddingModule = { ports, databaseName ? "wedding", serverName ? "_" }:
          (import "${inputs.wedding-page}/nixosModules/wedding.nix") {
            inherit ports databaseName serverName;
            packages = {
              backend    = inputs.wedding-page.packages.${system}.wedding-backend;
              staticRoot = inputs.wedding-page.packages.${system}.website;
            };
          };

        weddingOlimpo = weddingModule {
          ports        = { nginx = 8084; backend = 3001; database = 5432; };
          databaseName = "wedding";
          serverName   = "wedding.local";
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
            weddingOlimpo
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
            weddingOlimpo
            (home-manager-module { xmobarrc = ./xmobarrc-olimpo; })
          ];
          extraSpecialArgs = { xmonadShortenLength = 50; };
        };

        nixosConfigurations.xty = mkHost {
          hostModules = [
            ./xty.nix
            ./projects-xty.nix
            ./configuration-core.nix
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
