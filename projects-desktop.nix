{ config, lib, pkgs, inputs, ... }:
let
  system = pkgs.stdenv.hostPlatform.system;
  cfoDbPassword = "cfo-local-password";
  cfoDbPasswordFile = pkgs.writeText "cfo-db-password" cfoDbPassword;
in
{
  # Use the admin key (already a recipient in expedientes/secrets/secrets.nix)
  # as the agenix identity so desktop hosts can decrypt expedientes secrets.
  age.identityPaths = [ "/home/hhefesto/.ssh/hetzner_ed25519" ];

  age.secrets.expedientes-password-hash = {
    file  = inputs.expedientes + "/secrets/expedientes-password-hash.age";
    owner = "root";
    group = "root";
    mode  = "0400";
  };

  services.expedientes.backend.passwordHashFile =
    config.age.secrets.expedientes-password-hash.path;

  # Allow the expedientes and wedding backends (DynamicUser) to connect over
  # TCP without a password — dev desktops have no db secret file.
  services.postgresql.authentication = lib.mkAfter ''
    host all expedientes 127.0.0.1/32 trust
    host all expedientes ::1/128      trust
    host all wedding     127.0.0.1/32 trust
    host all wedding     ::1/128      trust
  '';

  # CFO's upstream module sets a postStart hook that fails hard if the role
  # does not exist yet, which prevents postgresql-setup.service from creating
  # ensureUsers. Make this hook idempotent and create the role if needed.
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

  services.nginx.recommendedGzipSettings = lib.mkForce false;

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

  # The wedding.local vhost (port 8084) and firewall opening are now provided
  # by the weddingOlimpo module, which also adds the /api/ reverse proxy.
  networking.hosts."127.0.0.1" = [ "wedding.local" ];
}
