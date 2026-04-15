{ config, lib, pkgs, inputs, ... }:
let
  system = pkgs.stdenv.hostPlatform.system;
  cfoDbPassword = "change-this-cfo-password";
in
{
  imports = [
    inputs.agenix.nixosModules.default
    inputs.expedientes.nixosModules.database
    inputs.expedientes.nixosModules.backend
    inputs.expedientes.nixosModules.frontend
    inputs.expedientes.nixosModules.nginx
  ];

  services.nginx.recommendedGzipSettings = lib.mkForce false;

  age.secrets.expedientes-db-password = {
    file = inputs.expedientes + "/secrets/expedientes-db-password.age";
    owner = "postgres";
    group = "postgres";
    mode = "0400";
  };

  age.secrets.expedientes-backend-env = {
    file = inputs.expedientes + "/secrets/expedientes-backend-env.age";
    owner = "root";
    group = "root";
    mode = "0400";
  };

  age.secrets.expedientes-password-hash = {
    file = inputs.expedientes + "/secrets/expedientes-password-hash.age";
    owner = "root";
    group = "root";
    mode = "0400";
  };

  services.expedientes.database = {
    enable = true;
    passwordFile = config.age.secrets.expedientes-db-password.path;
  };

  services.expedientes.backend = {
    enable = true;
    package = inputs.expedientes.packages.${system}.expedientes-backend;
    htmlDir = "/var/lib/expedientes/html";
    databaseUrlFile = config.age.secrets.expedientes-backend-env.path;
    passwordHashFile = config.age.secrets.expedientes-password-hash.path;
  };

  services.expedientes.frontend = {
    enable = true;
    staticRoot = inputs.expedientes.packages.${system}.expedientes-frontend-static;
  };

  services.expedientes.nginx = {
    enable = true;
    serverName = "_";
    port = 80;
  };

  systemd.tmpfiles.rules = [
    "d /var/lib/expedientes      0755 root root -"
    "d /var/lib/expedientes/html 0755 root root -"
  ];

  services.cfo.profile = {
    enable = true;
    mode = "production";
    serverName = "cfo.xty";

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

  services.nginx.virtualHosts."wedding.xty" = {
    listen = [
      { addr = "0.0.0.0"; port = 8084; }
      { addr = "[::]"; port = 8084; }
    ];
    root = inputs."wedding-page".packages.${system}.website;
    locations."/".tryFiles = "$uri $uri/ /index.html";
  };

  networking.firewall.allowedTCPPorts = [ 80 8082 8084 ];
}
