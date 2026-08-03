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
    wedding-page.url = "github:hhefesto/wedding-website";
    directo.url = "git+ssh://git@github.com/hhefesto/directo";
    # Single-Servant parity branch; both Olimpo and xty evaluate the same
    # application source, but deployment remains an explicit separate step.
    xpsoasis.url = "git+ssh://git@github.com/rdataa/xpsOasis?ref=xpsoasis-single-servant";
    # Spectra (web AAnalyzer): C++ engine + reflex frontend.
    # Prod home: aaspectra.xpsoasis.org.
    aanalyzer-classic.url = "git+ssh://git@github.com/rdataa/aanalyzer-classic?ref=headless-backend";
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
          inputs.wedding-page.nixosModules.default
          inputs.directo.nixosModules.default
          inputs.xpsoasis.nixosModules.default
          inputs.aanalyzer-classic.nixosModules.default
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

          services.wedding.profile = {
            enable = true;
            mode = "development";
            serverName = "wedding.local";
            ports = { nginx = 8084; backend = 3001; };
          };

          services.directo.profile = {
            enable = true;
            mode = "development";
            serverName = "directo.local";
            ports = { nginx = 8085; backend = 3002; };
          };

          services.xpsoasis.profile = {
            enable = true;
            mode = "development";
            serverName = "xpsoasis.local";
            cookieDomain = "xpsoasis.local";
            ports = { nginx = 8086; backend = 3003; };
          };

          # Spectra (web AAnalyzer) — sister app to xpsoasis, local only for now.
          services.aaspectra.profile = {
            enable = true;
            mode = "development";
            serverName = "aaspectra.xpsoasis.local";
            ports = { nginx = 8087; backend = 3004; };
            oasisUrl = "http://xpsoasis.local:8086";
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

          services.wedding.profile = {
            enable = true;
            mode = "production";
            serverName = "xty-y-dan.net";
            ports = { nginx = 80; backend = 3001; };
          };

          services.directo.profile = {
            enable = true;
            mode = "production";
            serverName = "directo.hhefesto.com";
            ports = { nginx = 80; backend = 3002; };
          };

          services.xpsoasis.profile = {
            enable = true;
            mode = "production";
            serverName = "xpsoasis.hhefesto.com";
            # Parent-domain session cookie so the Spectra sibling vhost can
            # authorize through /b/auth/me with the same cookie.
            cookieDomain = "xpsoasis.hhefesto.com";
            spectraUrl = "https://aaspectra.xpsoasis.hhefesto.com";
            ports = { nginx = 80; backend = 3003; };
          };

          # Spectra (web AAnalyzer) — production sibling of xpsoasis. nginx
          # port must be 80 so the ACME HTTP-01 challenge is reachable; the
          # engine stays on loopback 3004.
          services.aaspectra.profile = {
            enable = true;
            mode = "production";
            serverName = "aaspectra.xpsoasis.hhefesto.com";
            ports = { nginx = 80; backend = 3004; };
            oasisUrl = "https://xpsoasis.hhefesto.com";
          };

          # The aaspectra certificate order can only succeed once its A
          # record exists; keep the order unit out of activation so a
          # missing record cannot fail the switch (deploy war story 2).
          # The daily acme timer keeps retrying, so the real certificate
          # replaces the self-signed placeholder on its own once DNS
          # resolves — or start it manually:
          #   systemctl start acme-aaspectra.xpsoasis.hhefesto.com.service
          systemd.services."acme-aaspectra.xpsoasis.hhefesto.com".wantedBy =
            nixpkgs.lib.mkForce [ ];
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
            # 2026-07-07: a benign `user activation for root failed`
            # (dbus-broker user-unit reload on a headless host) made
            # magic-rollback treat a successful activation as failed; the
            # rollback re-activation then hung with all services stopped
            # (production outage). Pre-deploy checks gate correctness
            # instead; roll back manually via system profile generations.
            magicRollback = false;
            autoRollback = false;
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
            ++ lib.optionals (!(hasAll [ "expedientes" "wedding" "directo" "aanalyzer_yesod" ] xtyCfg.services.postgresql.ensureDatabases)) [
              "xty PostgreSQL ensureDatabases must contain expedientes, wedding, directo, and aanalyzer_yesod"
            ]
            ++ lib.optionals (!(hasAll [ "expedientes" "wedding" "directo" "analyzer" ] xtyPostgresUsers)) [
              "xty PostgreSQL ensureUsers must contain expedientes, wedding, directo, and analyzer"
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
            ++ lib.optionals (!(lib.hasInfix "ALTER USER directo" xtyPostgresSetupPostStart)) [
              "xty PostgreSQL setup must set the directo role password"
            ]
            ++ lib.optionals (!(lib.hasInfix "ALTER USER analyzer" xtyPostgresSetupPostStart)) [
              "xty PostgreSQL setup must set the analyzer role password"
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
            ++ lib.optionals (!(hasUnit "postgresql-setup.service" xtyCfg.systemd.services.directo-migrate.after)) [
              "directo-migrate must start after postgresql-setup.service"
            ]
            ++ lib.optionals (!(hasUnit "postgresql-setup.service" xtyCfg.systemd.services.directo-migrate.requires)) [
              "directo-migrate must require postgresql-setup.service"
            ]
            ++ lib.optionals (!(hasUnit "postgresql-setup.service" xtyCfg.systemd.services.directo-backend.after)) [
              "directo-backend must start after postgresql-setup.service"
            ]
            ++ lib.optionals (!(hasUnit "directo-migrate.service" xtyCfg.systemd.services.directo-backend.requires)) [
              "directo-backend must require directo-migrate.service"
            ]
            ++ lib.optionals (!(hasUnit "postgresql-setup.service" xtyCfg.systemd.services.xpsoasis-backend.after)) [
              "xpsoasis-backend must start after postgresql-setup.service"
            ]
            ++ lib.optionals (!(hasUnit "postgresql-setup.service" xtyCfg.systemd.services.xpsoasis-backend.requires)) [
              "xpsoasis-backend must require postgresql-setup.service"
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
            ++ lib.optionals (!(hasXtyVhost "directo.hhefesto.com")) [
              "nginx must define directo.hhefesto.com vhost"
            ]
            ++ lib.optionals (!(hasXtyVhost "xpsoasis.hhefesto.com")) [
              "nginx must define xpsoasis.hhefesto.com vhost"
            ]
            ++ lib.optionals (!(hasXtyVhost "aaspectra.xpsoasis.hhefesto.com")) [
              "nginx must define aaspectra.xpsoasis.hhefesto.com vhost"
            ]
            ++ lib.optionals (!(hasSsl443 "docxty.net")) [
              "docxty.net must listen on 443 with ssl"
            ]
            ++ lib.optionals (!(hasSsl443 "xty-y-dan.net")) [
              "xty-y-dan.net must listen on 443 with ssl"
            ]
            ++ lib.optionals (!(hasSsl443 "directo.hhefesto.com")) [
              "directo.hhefesto.com must listen on 443 with ssl"
            ]
            ++ lib.optionals (!(hasSsl443 "xpsoasis.hhefesto.com")) [
              "xpsoasis.hhefesto.com must listen on 443 with ssl"
            ]
            ++ lib.optionals (!(hasSsl443 "aaspectra.xpsoasis.hhefesto.com")) [
              "aaspectra.xpsoasis.hhefesto.com must listen on 443 with ssl"
            ]
            ++ lib.optionals ((xtyCfg.systemd.services.xpsoasis-backend.environment.AANALYZER_WORKER or "") != "1") [
              "xpsoasis backend must own the deferred-job worker (AANALYZER_WORKER=1)"
            ]
            ++ lib.optionals ((toString xtyCfg.services.wedding.backend.databaseUrlFile) != "/run/agenix/wedding-backend-env") [
              "wedding backend must use the production DATABASE_URL secret"
            ]
            ++ lib.optionals ((toString xtyCfg.services.wedding.backend.adminPasswordHashFile) != "/run/credentials/wedding-backend.service/admin-hash") [
              "wedding backend must read the admin hash via systemd LoadCredential"
            ]
            ++ lib.optionals ((toString (lib.head (xtyCfg.systemd.services.directo-backend.serviceConfig.EnvironmentFile or [ "" ]))) != "/run/agenix/directo-backend-env") [
              "directo backend must use the production env secret (DATABASE_URL + Mercado Pago)"
            ]
            ++ lib.optionals ((xtyCfg.systemd.services.directo-backend.environment.DIRECTO_ADMIN_PASSWORD_HASH_FILE or "") != "/run/credentials/directo-backend.service/admin-hash") [
              "directo backend must read the admin hash via systemd LoadCredential"
            ]
            ++ lib.optionals ((toString (lib.head (xtyCfg.systemd.services.xpsoasis-backend.serviceConfig.EnvironmentFile or [ "" ]))) != "/run/agenix/xpsoasis-backend-env") [
              "xpsoasis backend must use the production AANALYZER_PGPASS secret"
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
          # Health check for the expedientes (docxty) restic backups on xty.
          # Fails unless the timer is live, the last run succeeded, the latest
          # snapshot is fresh (< 26 h) and contains both the DB dump and the
          # HTML dir, and the repository passes a metadata integrity check.
          checkDocxtyBackups = pkgs.writeShellApplication {
            name = "check-docxty-backups";
            runtimeInputs = [ pkgs.coreutils pkgs.gnugrep pkgs.jq pkgs.openssh ];
            text = ''
              set -euo pipefail

              host="''${DOCXTY_BACKUP_HOST:-root@62.238.6.4}"
              max_age_seconds=$(( 26 * 3600 ))
              ssh_opts=(-o BatchMode=yes -o ConnectTimeout=10)

              remote() {
                # shellcheck disable=SC2029
                ssh "''${ssh_opts[@]}" "$host" "$@"
              }

              fail() {
                printf 'check-docxty-backups: FAIL: %s\n' "$*" >&2
                exit 1
              }

              echo "==> 1/4 expedientes-backup.timer"
              remote "systemctl is-active --quiet expedientes-backup.timer" \
                || fail "expedientes-backup.timer is not active on $host"
              remote "systemctl show expedientes-backup.timer -p LastTriggerUSec -p NextElapseUSecRealtime --no-pager"

              echo "==> 2/4 last expedientes-backup.service run"
              result="$(remote "systemctl show -p Result --value expedientes-backup.service" | tr -d '[:space:]')"
              [ "$result" = "success" ] \
                || fail "last expedientes-backup.service run: Result=$result (expected success)"
              echo "Result=success"

              echo "==> 3/4 latest restic snapshot (freshness + contents)"
              snapshot_json="$(remote "expedientes-restic snapshots --latest 1 --json")"
              snapshot_count="$(jq 'length' <<< "$snapshot_json")"
              [ "$snapshot_count" -ge 1 ] || fail "restic repository has no snapshots"

              snapshot_time="$(jq -r '.[-1].time' <<< "$snapshot_json")"
              snapshot_epoch="$(date -d "$snapshot_time" +%s)"
              now_epoch="$(date +%s)"
              age_seconds=$(( now_epoch - snapshot_epoch ))
              [ "$age_seconds" -le "$max_age_seconds" ] \
                || fail "latest snapshot is $(( age_seconds / 3600 )) h old (limit: 26 h)"

              jq -e '.[-1].paths | any(endswith("expedientes.dump"))' <<< "$snapshot_json" >/dev/null \
                || fail "latest snapshot does not contain expedientes.dump"
              # Patient HTML lives in the DB (patients.body_html) since the
              # docxty migration; the legacy html dir is only in older
              # snapshots (e.g. 53235259, 2026-07-04), so its absence here
              # is expected — warn, don't fail.
              jq -e '.[-1].paths | any(. == "/var/lib/expedientes/html")' <<< "$snapshot_json" >/dev/null \
                || echo "note: snapshot has no /var/lib/expedientes/html (expected: patient HTML lives in the DB)"
              jq -r '.[-1] | "id=\(.short_id) time=\(.time) paths=\(.paths | join(","))"' <<< "$snapshot_json"
              echo "snapshot age: $(( age_seconds / 3600 )) h"

              if [ "''${DOCXTY_BACKUP_CHECK_FAST:-0}" = "1" ]; then
                echo "==> 4/4 restic check skipped (DOCXTY_BACKUP_CHECK_FAST=1)"
              else
                echo "==> 4/4 restic repository integrity (metadata)"
                remote "expedientes-restic check" \
                  || fail "restic check reported errors"
              fi

              echo "check-docxty-backups: all checks passed"
            '';
          };
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

              # NOTE first deploy of directo/xpsoasis: these services do not
              # exist on xty yet, so this live check will fail; deploy that
              # one time with `deploy .#xty` directly, then this gate applies.
              for service in postgresql nginx expedientes-backend wedding-migrate wedding-backend directo-migrate directo-backend xpsoasis-backend; do
                remote "systemctl is-active --quiet $service" \
                  || fail "$service is not active on $host"
              done

              expedientes_tables="$(remote "runuser -u postgres -- psql -d expedientes -tAc \"select count(*) from information_schema.tables where table_schema='public';\"" | tr -d '[:space:]')"
              [[ "$expedientes_tables" =~ ^[0-9]+$ ]] \
                || fail "could not count expedientes public tables"
              [ "$expedientes_tables" -gt 0 ] \
                || fail "expedientes database has no public tables"

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

              echo "==> Checking docxty (expedientes) backups"
              ${checkDocxtyBackups}/bin/check-docxty-backups

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

        apps.check-docxty-backups = {
          type = "app";
          program = "${checkDocxtyBackups}/bin/check-docxty-backups";
        };

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
