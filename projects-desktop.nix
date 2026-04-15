{ pkgs, inputs, ... }:
let
  system = pkgs.stdenv.hostPlatform.system;
  cfoDbPassword = "cfo-local-password";
in
{
  imports = [ ./expedientes-local.nix ];

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
