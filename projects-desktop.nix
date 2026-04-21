{ config, lib, pkgs, inputs, ... }:
let
  system = pkgs.stdenv.hostPlatform.system;
  cfoDbPassword = "cfo-local-password";
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

  # Allow the expedientes backend (DynamicUser) to connect as the expedientes
  # role over TCP without a password — dev desktops have no db secret file.
  services.postgresql.authentication = lib.mkAfter ''
    host all expedientes 127.0.0.1/32 trust
    host all expedientes ::1/128      trust
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
      dbPasswordFile = pkgs.writeText "cfo-db-password" cfoDbPassword;
      backendEnvFile = pkgs.writeText "cfo-backend-env" ''
        DATABASE_URL=postgres://cfo:${cfoDbPassword}@localhost:5432/cfo
      '';
    };

    tls.enableACME = false;
    tls.forceSSL = false;
  };

  services.nginx.virtualHosts."wedding.local" = {
    listen = [
      { addr = "0.0.0.0"; port = 8084; }
      { addr = "[::]"; port = 8084; }
    ];
    root = inputs."wedding-page".packages.${system}.website;
    locations."/".tryFiles = "$uri $uri/ /index.html";
  };

  networking.firewall.allowedTCPPorts = [ 8084 ];
}
