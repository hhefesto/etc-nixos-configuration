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
    let
      xtyPostgresMajor = "16";
    in
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

        cfo =
          { profile ? "desktop"
          , serverName ? if profile == "production" then "cfo-vision.com" else "cfo.local"
          , ports ? if profile == "production"
              then { frontend = 8083; backend = 3033; database = 5432; nginx = 80; }
              else { frontend = 8083; backend = 3033; database = 5432; nginx = 8082; }
          }:
          { config, lib, pkgs, ... }:
          let
            cfoDbPassword = "cfo-local-password";
            cfoDbPasswordFile = pkgs.writeText "cfo-db-password" cfoDbPassword;
            cfoBackendEnvFile = pkgs.writeText "cfo-backend-env" ''
              DATABASE_URL=postgres://cfo:${cfoDbPassword}@localhost:5432/cfo
            '';
          in {
            imports = [
              inputs.agenix.nixosModules.default
              ((import "${inputs."cfo-as-a-service"}/nixosModules/cfo-as-a-service.nix") {
                mode = if profile == "production" then "production" else "staging";
                inherit ports serverName;
                databaseName = "cfo";
                packages = {
                  backend = inputs."cfo-as-a-service".packages.${system}.cfo-backend;
                  frontendStatic = inputs."cfo-as-a-service".packages.${system}.cfo-frontend-static;
                };
                secrets = lib.optionalAttrs (profile == "desktop") {
                  dbPasswordFile = cfoDbPasswordFile;
                  backendEnvFile = cfoBackendEnvFile;
                };
                tls = {
                  enableACME = profile == "production";
                  forceSSL = profile == "production";
                  acmeEmail = if profile == "production" then "hhefesto@rdataa.com" else null;
                };
              })
            ];

            config = lib.mkIf (profile == "production") {
                age.secrets.cfo-db-password = {
                  file = inputs."cfo-as-a-service" + "/secrets/cfo-db-password.age";
                  owner = "postgres";
                  group = "postgres";
                  mode = "0400";
                };

                age.secrets.cfo-backend-env = {
                  file = inputs."cfo-as-a-service" + "/secrets/cfo-backend-env.age";
                  owner = "root";
                  group = "root";
                  mode = "0400";
                };

                services.cfo.profile = {
                  secrets = {
                    dbPasswordFile = config.age.secrets.cfo-db-password.path;
                    backendEnvFile = config.age.secrets.cfo-backend-env.path;
                  };
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
          { config, lib, ... }:
          {
            imports = [
              inputs.agenix.nixosModules.default
              ((import "${inputs.wedding-page}/nixosModules/wedding.nix") {
                inherit ports serverName;
                databaseName = "wedding";
                localHostAlias = profile == "desktop";
                localPostgresTrust = profile == "desktop";
                recommendedGzipSettings = false;
                cookieSecure = profile == "production";
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

            config = lib.mkIf (profile == "production") {
              age.secrets.wedding-db-password = {
                file = inputs.wedding-page + "/secrets/wedding-db-password.age";
                owner = "postgres";
                group = "postgres";
                mode = "0400";
              };

              age.secrets.wedding-backend-env = {
                file = inputs.wedding-page + "/secrets/wedding-backend-env.age";
                owner = "root";
                group = "root";
                mode = "0400";
              };

              age.secrets.wedding-admin-password-hash = {
                file = inputs.wedding-page + "/secrets/wedding-admin-password-hash.age";
                owner = "root";
                group = "root";
                mode = "0444";
              };

              services.wedding.database.passwordFile =
                config.age.secrets.wedding-db-password.path;
              services.wedding.backend.databaseUrlFile =
                config.age.secrets.wedding-backend-env.path;
              services.wedding.backend.adminPasswordHashFile =
                config.age.secrets.wedding-admin-password-hash.path;
            };
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
            (cfo { profile = "production"; })
            ({ config, lib, pkgs, ... }: {
              services.postgresql.package = pkgs.${"postgresql_${xtyPostgresMajor}"};

              # PostgreSQL 17 creates ensureUsers in postgresql-setup.service;
              # legacy app modules still attach password changes to postgresql.service.
              systemd.services.postgresql.postStart = lib.mkForce "";
              systemd.services.postgresql-setup.postStart = lib.mkAfter ''
                pw="$(${pkgs.coreutils}/bin/cat ${config.age.secrets.expedientes-db-password.path})"
                ${config.services.postgresql.package}/bin/psql \
                  -v ON_ERROR_STOP=1 -d postgres -v pw="$pw" <<'SQL'
                ALTER USER expedientes WITH PASSWORD :'pw';
                SQL
              '';
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

      perSystem = { pkgs, system, ... }:
        let
          lib = pkgs.lib;
          xtyCfg = self.nixosConfigurations.xty.config;
          xtyPostgresPackageMajor = lib.versions.major xtyCfg.services.postgresql.package.version;
          xtyPostgresUsers = map (user: user.name) xtyCfg.services.postgresql.ensureUsers;
          xtyPostgresSetupPostStart = xtyCfg.systemd.services.postgresql-setup.postStart or "";
          xtyNginxVhosts = xtyCfg.services.nginx.virtualHosts;
          hasXtyVhost = name: builtins.hasAttr name xtyNginxVhosts;
          hasSsl443 = name:
            let listen = if hasXtyVhost name then xtyNginxVhosts.${name}.listen else [];
            in builtins.any (entry: entry.port == 443 && (entry.ssl or false)) listen;
          hasAll = expected: actual: builtins.all (value: builtins.elem value actual) expected;
          hasUnit = unit: units: builtins.elem unit units;
          checkFailures =
            lib.optionals (xtyPostgresPackageMajor != xtyPostgresMajor) [
              "xty PostgreSQL package major is ${xtyPostgresPackageMajor}, expected ${xtyPostgresMajor}"
            ]
            ++ lib.optionals (!(hasAll [ "expedientes" "wedding" "cfo" ] xtyCfg.services.postgresql.ensureDatabases)) [
              "xty PostgreSQL ensureDatabases must contain expedientes, wedding, and cfo"
            ]
            ++ lib.optionals (!(hasAll [ "expedientes" "wedding" "cfo" ] xtyPostgresUsers)) [
              "xty PostgreSQL ensureUsers must contain expedientes, wedding, and cfo"
            ]
            ++ lib.optionals (xtyCfg.systemd.services.postgresql.postStart != "") [
              "xty PostgreSQL password hooks must not run in postgresql.postStart"
            ]
            ++ lib.optionals (!(lib.hasInfix "ALTER USER expedientes" xtyPostgresSetupPostStart)) [
              "xty PostgreSQL setup must set the expedientes role password"
            ]
            ++ lib.optionals (!(lib.hasInfix "ALTER USER wedding" xtyPostgresSetupPostStart)) [
              "xty PostgreSQL setup must set the wedding role password"
            ]
            ++ lib.optionals (!(lib.hasInfix "ALTER USER cfo" xtyPostgresSetupPostStart)) [
              "xty PostgreSQL setup must set the cfo role password"
            ]
            ++ lib.optionals (!(hasUnit "postgresql-setup.service" xtyCfg.systemd.services.wedding-migrate.after)) [
              "wedding-migrate must start after postgresql-setup.service"
            ]
            ++ lib.optionals (!(hasUnit "postgresql-setup.service" xtyCfg.systemd.services.wedding-migrate.requires)) [
              "wedding-migrate must require postgresql-setup.service"
            ]
            ++ lib.optionals (!(hasUnit "postgresql-setup.service" xtyCfg.systemd.services.wedding-backend.after)) [
              "wedding-backend must start after postgresql-setup.service"
            ]
            ++ lib.optionals (!(hasUnit "wedding-migrate.service" xtyCfg.systemd.services.wedding-backend.requires)) [
              "wedding-backend must require wedding-migrate.service"
            ]
            ++ lib.optionals (!(hasUnit "postgresql-setup.service" xtyCfg.systemd.services.cfo-backend.after)) [
              "cfo-backend must start after postgresql-setup.service"
            ]
            ++ lib.optionals (!(hasUnit "postgresql-setup.service" xtyCfg.systemd.services.cfo-backend.requires)) [
              "cfo-backend must require postgresql-setup.service"
            ]
            ++ lib.optionals ((xtyCfg.systemd.services.expedientes-seed.unitConfig.ConditionPathExists or "") != "!/var/lib/expedientes/.seeded") [
              "expedientes-seed must stay guarded by /var/lib/expedientes/.seeded"
            ]
            ++ lib.optionals (!(hasXtyVhost "docxty.net")) [
              "nginx must define docxty.net vhost"
            ]
            ++ lib.optionals (!(hasXtyVhost "xty-y-dan.net")) [
              "nginx must define xty-y-dan.net vhost"
            ]
            ++ lib.optionals (!(hasXtyVhost "cfo-vision.com")) [
              "nginx must define cfo-vision.com vhost"
            ]
            ++ lib.optionals (!(hasSsl443 "docxty.net")) [
              "docxty.net must listen on 443 with ssl"
            ]
            ++ lib.optionals (!(hasSsl443 "xty-y-dan.net")) [
              "xty-y-dan.net must listen on 443 with ssl"
            ]
            ++ lib.optionals (!(hasSsl443 "cfo-vision.com")) [
              "cfo-vision.com must listen on 443 with ssl"
            ]
            ++ lib.optionals ((toString xtyCfg.services.wedding.backend.databaseUrlFile) != "/run/agenix/wedding-backend-env") [
              "wedding backend must use the production DATABASE_URL secret"
            ]
            ++ lib.optionals ((toString xtyCfg.services.wedding.backend.adminPasswordHashFile) != "/run/agenix/wedding-admin-password-hash") [
              "wedding backend must use the production admin hash secret"
            ]
            ++ lib.optionals ((toString xtyCfg.services.cfo.backend.databaseUrlFile) != "/run/agenix/cfo-backend-env") [
              "cfo backend must use the production DATABASE_URL secret"
            ];
          preDeployXty = pkgs.runCommand "pre-deploy-xty" {} ''
            ${if checkFailures == [] then ''
              echo "pre-deploy-xty pure checks passed"
              touch "$out"
            '' else ''
              printf '%s\n' ${lib.escapeShellArgs checkFailures}
              exit 1
            ''}
          '';
          preDeployXtyLive = pkgs.writeShellApplication {
            name = "pre-deploy-xty-live";
            runtimeInputs = [ pkgs.coreutils pkgs.gnugrep pkgs.openssh ];
            text = ''
              set -euo pipefail

              host="''${PRE_DEPLOY_XTY_HOST:-root@62.238.6.4}"
              desired_major="${xtyPostgresMajor}"
              ssh_opts=(-o BatchMode=yes -o ConnectTimeout=10)

              remote() {
                # shellcheck disable=SC2029
                ssh "''${ssh_opts[@]}" "$host" "$@"
              }

              fail() {
                printf 'pre-deploy-xty-live: %s\n' "$*" >&2
                exit 1
              }

              live_version_num="$(remote "runuser -u postgres -- psql -tAc 'SHOW server_version_num;'" | tr -d '[:space:]')"
              [[ "$live_version_num" =~ ^[0-9]+$ ]] || fail "could not read live PostgreSQL server_version_num from $host"
              live_major="$((live_version_num / 10000))"
              if [ "$live_major" != "$desired_major" ]; then
                fail "live PostgreSQL major is $live_major, but this deployment is pinned to $desired_major"
              fi

              remote "test -d /var/lib/postgresql/$desired_major" \
                || fail "missing /var/lib/postgresql/$desired_major on $host"
              remote "test -e /var/lib/expedientes/.seeded" \
                || fail "missing /var/lib/expedientes/.seeded; expedientes seed could drop and restore the DB"

              for service in postgresql nginx expedientes-backend wedding-migrate wedding-backend cfo-backend; do
                remote "systemctl is-active --quiet $service" \
                  || fail "$service is not active on $host"
              done

              expedientes_tables="$(remote "runuser -u postgres -- psql -d expedientes -tAc \"select count(*) from information_schema.tables where table_schema='public';\"" | tr -d '[:space:]')"
              [[ "$expedientes_tables" =~ ^[0-9]+$ ]] \
                || fail "could not count expedientes public tables"
              [ "$expedientes_tables" -gt 0 ] \
                || fail "expedientes database has no public tables"

              cfo_tables="$(remote "runuser -u postgres -- psql -d cfo -tAc \"select count(*) from information_schema.tables where table_schema='public';\"" | tr -d '[:space:]')"
              [[ "$cfo_tables" =~ ^[0-9]+$ ]] \
                || fail "could not count cfo public tables"
              [ "$cfo_tables" -gt 0 ] \
                || fail "cfo database has no public tables"

              echo "pre-deploy-xty-live checks passed"
            '';
          };
          deployXty = pkgs.writeShellApplication {
            name = "deploy-xty";
            runtimeInputs = [
              pkgs.nix
              deploy-rs.packages.${system}.deploy-rs
            ];
            text = ''
              set -euo pipefail

              echo "==> Running pure xty predeploy check"
              nix build .#checks.x86_64-linux.pre-deploy-xty -L

              echo "==> Running live xty predeploy check"
              ${preDeployXtyLive}/bin/pre-deploy-xty-live

              echo "==> Building xty system closure"
              nix build .#nixosConfigurations.xty.config.system.build.toplevel -L

              echo "==> Deploying xty"
              deploy .#xty
            '';
          };
        in {
        checks.pre-deploy-xty = preDeployXty;

        apps.pre-deploy-xty-live = {
          type = "app";
          program = "${preDeployXtyLive}/bin/pre-deploy-xty-live";
        };

        apps.deploy-xty = {
          type = "app";
          program = "${deployXty}/bin/deploy-xty";
        };

        devShells.default = pkgs.mkShell {
          packages = [
            deploy-rs.packages.${system}.deploy-rs
            inputs.agenix.packages.${system}.default
            pkgs.haskell-language-server
            pkgs.nil
          ];
        };

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
