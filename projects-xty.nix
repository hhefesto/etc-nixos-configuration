{ config, lib, pkgs, inputs, ... }:
let
  system = pkgs.stdenv.hostPlatform.system;
in
{
  imports = [
    inputs.agenix.nixosModules.default
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

  # Wire agenix-decrypted secret paths into the expedientes sub-module options.
  # The stack itself (ports, packages, nginx, tmpfiles) is provided by expedientesXty
  # in flake.nix via nixosModules.expedientes.
  services.expedientes.database.passwordFile =
    config.age.secrets.expedientes-db-password.path;

  services.expedientes.backend.databaseUrlFile  =
    config.age.secrets.expedientes-backend-env.path;
  services.expedientes.backend.passwordHashFile =
    config.age.secrets.expedientes-password-hash.path;

  systemd.services.expedientes-seed.after =
    lib.mkAfter [ "postgresql-setup.service" ];
  systemd.services.expedientes-seed.requires =
    lib.mkAfter [ "postgresql-setup.service" ];

  services.nginx.virtualHosts."wedding.xty" = {
    listen = [
      { addr = "0.0.0.0"; port = 8084; }
      { addr = "[::]"; port = 8084; }
    ];
    root = inputs."wedding-page".packages.${system}.website;
    locations."/".tryFiles = "$uri $uri/ /index.html";
  };

  systemd.tmpfiles.rules = [
    "d /var/lib/expedientes-bootstrap 0700 root root -"
  ];

  networking.firewall.allowedTCPPorts = [ 80 8084 ];
}
