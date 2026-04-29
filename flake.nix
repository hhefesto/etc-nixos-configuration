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
    docxty.url = "git+ssh://git@github.com/hhefesto/docxty";
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

        cfo = { profile ? "desktop" }:
          { config, lib, pkgs, ... }:
          let
            cfoDbPassword = "cfo-local-password";
            cfoDbPasswordFile = pkgs.writeText "cfo-db-password" cfoDbPassword;
          in {
            imports = [
              ((import "${inputs."cfo-as-a-service"}/nixosModules/cfo-as-a-service.nix") null)
            ];

            config = lib.mkIf (profile == "desktop") {
              systemd.services.postgresql.postStart = lib.mkForce ''
                pw="$(cat ${cfoDbPasswordFile})"
                psql -v ON_ERROR_STOP=1 -d postgres -v pw="$pw" <<'SQL'
                  DO $do$
                  BEGIN
                    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'cfo') THEN
                      CREATE ROLE cfo LOGIN;
                    END IF;
                  END
                  $do$;
                  ALTER ROLE cfo WITH PASSWORD :'pw';
                SQL
              '';

              services.cfo.profile = {
                enable = true;
                mode = "staging";
                serverName = "cfo.local";

                ports = {
                  frontend = 8083;
                  backend = 3033;
                  database = 5432;
                  nginx = 8082;
                };

                packages = {
                  backend = inputs."cfo-as-a-service".packages.${system}.cfo-backend;
                  frontendStatic = inputs."cfo-as-a-service".packages.${system}.cfo-frontend-static;
                };

                secrets = {
                  dbPasswordFile = cfoDbPasswordFile;
                  backendEnvFile = pkgs.writeText "cfo-backend-env" ''
                    DATABASE_URL=postgres://cfo:${cfoDbPassword}@localhost:5432/cfo
                  '';
                };

                tls.enableACME = false;
                tls.forceSSL = false;
              };
            };
          };

        expedientes =
          { profile ? "desktop"
          , serverName ? "_"
          }:
          { config, lib, ... }:
          {
            imports = [
              inputs.agenix.nixosModules.default
              ((import "${inputs.docxty}/nixosModules/expedientes.nix") {
                inherit serverName;
                ports        = { nginx = 80; backend = 3000; database = 5432; };
                databaseName = "expedientes";
                htmlDir      = null;
                startingBackup = {
                  dump = "/var/lib/expedientes-bootstrap/expedientes.dump";
                };
                packages = {
                  backend        = inputs.docxty.packages.${system}.expedientes-backend;
                  frontendStatic = inputs.docxty.packages.${system}.expedientes-frontend-static;
                };
              })
            ];

            config = lib.mkMerge [
              {
                services.nginx.recommendedGzipSettings = lib.mkForce false;
              }

              (lib.mkIf (profile == "desktop") {
                age.identityPaths = [ "/home/hhefesto/.ssh/hetzner_ed25519" ];

                age.secrets.expedientes-password-hash = {
                  file  = inputs.docxty + "/secrets/expedientes-password-hash.age";
                  owner = "root";
                  group = "root";
                  mode  = "0400";
                };

                services.expedientes.backend.passwordHashFile =
                  config.age.secrets.expedientes-password-hash.path;

                services.postgresql.authentication = lib.mkAfter ''
                  host all expedientes 127.0.0.1/32 trust
                  host all expedientes ::1/128      trust
                '';
              })

              (lib.mkIf (profile == "production") {
                age.secrets.expedientes-db-password = {
                  file = inputs.docxty + "/secrets/expedientes-db-password.age";
                  owner = "postgres";
                  group = "postgres";
                  mode = "0400";
                };

                age.secrets.expedientes-backend-env = {
                  file = inputs.docxty + "/secrets/expedientes-backend-env.age";
                  owner = "root";
                  group = "root";
                  mode = "0400";
                };

                age.secrets.expedientes-password-hash = {
                  file = inputs.docxty + "/secrets/expedientes-password-hash.age";
                  owner = "root";
                  group = "root";
                  mode = "0400";
                };

                services.expedientes.database.passwordFile =
                  config.age.secrets.expedientes-db-password.path;
                services.expedientes.backend.databaseUrlFile =
                  config.age.secrets.expedientes-backend-env.path;
                services.expedientes.backend.passwordHashFile =
                  config.age.secrets.expedientes-password-hash.path;

                security.acme = {
                  acceptTerms = true;
                  defaults.email = "hhefesto@rdataa.com";
                };

                services.nginx.virtualHosts.${serverName} = {
                  enableACME = true;
                  forceSSL = true;
                  listen = lib.mkAfter [
                    { addr = "0.0.0.0"; port = 443; ssl = true; }
                    { addr = "[::]"; port = 443; ssl = true; }
                  ];
                };

                systemd.services.expedientes-seed.after =
                  lib.mkAfter [ "postgresql-setup.service" ];
                systemd.services.expedientes-seed.requires =
                  lib.mkAfter [ "postgresql-setup.service" ];

                systemd.tmpfiles.rules = [
                  "d /var/lib/expedientes-bootstrap 0700 root root -"
                ];

                networking.firewall.allowedTCPPorts = [ 443 ];
              })
            ];
          };

        wedding =
          { serverName ? "_"
          , profile ? "desktop"
          , ports ? { nginx = 8084; backend = 3001; database = 5432; }
          }:
          { ... }:
          {
            imports = [
              ((import "${inputs.wedding-page}/nixosModules/wedding.nix") {
                inherit ports serverName;
                databaseName = "wedding";
                localHostAlias = profile == "desktop";
                localPostgresTrust = profile == "desktop";
                recommendedGzipSettings = false;
                tls = {
                  enableACME = profile == "production";
                  forceSSL = profile == "production";
                  openFirewall = profile == "production";
                };
                acme = {
                  acceptTerms = profile == "production";
                  email = "hhefesto@rdataa.com";
                };
                packages = {
                  backend    = inputs.wedding-page.packages.${system}.wedding-backend;
                  staticRoot = inputs.wedding-page.packages.${system}.website;
                };
              })
            ];
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
            ./configuration.nix
            ./configuration-gui.nix
            (cfo {})
            (expedientes {})
            (wedding { serverName = "wedding.local"; })
            (home-manager-module { xmobarrc = ./xmobarrc-delfos; })
          ];
          extraSpecialArgs = { xmonadShortenLength = 26; };
        };

        nixosConfigurations.olimpo = mkHost {
          hostModules = [
            ./olimpo.nix
            ./configuration.nix
            ./configuration-gui.nix
            (cfo {})
            (expedientes {})
            (wedding { serverName = "wedding.local"; })
            (home-manager-module { xmobarrc = ./xmobarrc-olimpo; })
          ];
          extraSpecialArgs = { xmonadShortenLength = 50; };
        };

        nixosConfigurations.xty = mkHost {
          hostModules = [
            ./xty.nix
            ./configuration-core.nix
            (wedding {
              profile = "production";
              serverName = "xty-y-dan.net";
              ports = { nginx = 80; backend = 3001; database = 5432; };
            })
            (expedientes {
              profile = "production";
              serverName = "docxty.net";
            })
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
