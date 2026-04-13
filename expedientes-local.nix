{ config, lib, pkgs, inputs, ... }:
{
  imports = [
    inputs.expedientes.nixosModules.database
    inputs.expedientes.nixosModules.backend
    inputs.expedientes.nixosModules.frontend
    inputs.expedientes.nixosModules.nginx
  ];

  nixpkgs.config.permittedInsecurePackages = [ "libsoup-2.74.3" ];

  services.expedientes.database.enable = true;

  # Allow the backend (DynamicUser) to connect as the expedientes role over TCP
  # without a password.  Appended after NixOS's default peer/ident rules.
  services.postgresql.authentication = lib.mkAfter ''
    host all expedientes 127.0.0.1/32 trust
    host all expedientes ::1/128      trust
  '';

  services.expedientes.backend = {
    enable  = true;
    package = inputs.expedientes.packages.x86_64-linux.expedientes-backend;
    htmlDir = "/var/lib/expedientes/html";  # matches production path
    # databaseUrl default: postgres://expedientes@localhost:5432/expedientes (no password)
    # passwordHashFile null → falls back to hardcoded dev hash (soyunadoctorapato)
  };

  # The backend runs as DynamicUser and can't traverse /home/hhefesto (mode 700).
  # Bind-mount the local HTML checkout into the expected system path so the
  # service sees it at /var/lib/expedientes/html without needing home dir access.
  systemd.services.expedientes-backend.serviceConfig.BindReadOnlyPaths =
    [ "/home/hhefesto/src/expedientes/respaldo-expedientes:/var/lib/expedientes/html" ];

  services.expedientes.frontend = {
    enable  = true;
    package = inputs.expedientes.packages.x86_64-linux.expedientes-frontend;
  };

  services.expedientes.nginx.enable = true;

  systemd.tmpfiles.rules = [
    "d /var/lib/expedientes      0755 root root -"
    "d /var/lib/expedientes/html 0755 root root -"
  ];

  networking.firewall.allowedTCPPorts = [ 80 8080 ];
}
