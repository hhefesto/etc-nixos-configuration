{
  description = "hhefesto's system configurations";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
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
    opencode.url = "github:anomalyco/opencode/c5db39f6268a36194a7fe5f833ae3197dfe250b6";
    telomare.url = "git+ssh://git@github.com/hhefesto/stand-in-language?ref=source-locations";
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
            inherit (inputs) spacemacs telomare;
            inherit xmobarrc;
          };
        };

        # Each project repo exports one canonical NixOS module
        # (nixosModules.default) with a services.<name>.profile.* interface.
        # Only collide-able facts (ports, database name, serverName, mode)
        # live here; everything project-dependent is in the project repos.
        projectModules = [
          inputs.agenix.nixosModules.default
          inputs.docxty.nixosModules.default
          inputs."cfo-as-a-service".nixosModules.default
          inputs.wedding-page.nixosModules.default
        ];

        workstationServices = {
          imports = projectModules;

          # Workstations decrypt the shared dev secrets (expedientes
          # password hash) with the admin key instead of their host keys.
          age.identityPaths = [ "/home/hhefesto/.ssh/hetzner_ed25519" ];

          services.expedientes.profile = {
            enable = true;
            mode = "development";
            serverName = "docxty.local";
            ports = { nginx = 80; backend = 3000; };
            startingBackup.dump = "/var/lib/expedientes-bootstrap/expedientes.dump";
          };

          services.cfo.profile = {
            enable = true;
            mode = "development";
            serverName = "cfo.local";
            ports = { nginx = 8082; backend = 3033; frontend = 8083; };
          };

          services.wedding.profile = {
            enable = true;
            mode = "development";
            serverName = "wedding.local";
            ports = { nginx = 8084; backend = 3001; };
          };
        };

        xtyServices = {
          imports = projectModules;

          services.expedientes.profile = {
            enable = true;
            mode = "production";
            serverName = "docxty.net";
            ports = { nginx = 80; backend = 3000; };
            startingBackup.dump = "/var/lib/expedientes-bootstrap/expedientes.dump";
          };

          services.cfo.profile = {
            enable = true;
            mode = "production";
            serverName = "cfo-vision.com";
            ports = { nginx = 80; backend = 3033; frontend = 8083; };
          };

          services.wedding.profile = {
            enable = true;
            mode = "production";
            serverName = "xty-y-dan.net";
            ports = { nginx = 80; backend = 3001; };
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
            workstationServices
            (home-manager-module { xmobarrc = ./xmobarrc-delfos; })
          ];
          extraSpecialArgs = { xmonadShortenLength = 26; };
        };

        nixosConfigurations.olimpo = mkHost {
          hostModules = [
            ./olimpo.nix
            ./configuration.nix
            ./configuration-gui.nix
            workstationServices
            (home-manager-module { xmobarrc = ./xmobarrc-olimpo; })
          ];
          extraSpecialArgs = { xmonadShortenLength = 50; };
        };

        nixosConfigurations.xty = mkHost {
          hostModules = [
            ./xty.nix
            ./configuration-core.nix
            xtyServices
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
            ++ lib.optionals (lib.hasInfix "ALTER USER" (xtyCfg.systemd.services.postgresql.postStart or "")) [
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
            ++ lib.optionals ((toString xtyCfg.services.wedding.backend.adminPasswordHashFile) != "/run/credentials/wedding-backend.service/admin-hash") [
              "wedding backend must read the admin hash via systemd LoadCredential"
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
