{ pkgs, ... }:
{
  imports = [ ./hardware-configuration-xty.nix ];

  # Host concern: the production data directory was initialised with
  # PostgreSQL 16. Never bump without a migration plan (pre-deploy checks
  # assert this major).
  services.postgresql.package = pkgs.postgresql_16;

  networking.hostName = "xty";

  # hhefesto.com's DNS is broken (2026-09-18). nginx resolves proxy_pass
  # upstreams at start-up, and the aaspectra vhost proxies to
  # xpsoasis.hhefesto.com, so without this pin nginx refuses to start and
  # every vhost (docxty.net included) goes down on the next restart.
  # Harmless once DNS returns: these names point here anyway.
  networking.hosts."62.238.6.4" = [
    "xpsoasis.hhefesto.com"
    "aaspectra.xpsoasis.hhefesto.com"
    "directo.hhefesto.com"
    "refl.hhefesto.com"
  ];
  networking.nameservers = [ "1.1.1.1" "8.8.8.8" ];
  networking.useDHCP = false;

  networking.interfaces.enp1s0.ipv4.addresses = [
    {
      address = "62.238.6.4";
      prefixLength = 32;
    }
  ];

  networking.defaultGateway = {
    address = "172.31.1.1";
    interface = "enp1s0";
  };

  services.openssh.settings = {
    PermitRootLogin = "prohibit-password";
    PasswordAuthentication = false;
  };

  services.fail2ban = {
    enable = true;
    maxretry = 5;
    bantime = "1h";
    bantime-increment.enable = true;
  };

  security.sudo.wheelNeedsPassword = false;

  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJcDIsto/6GS7XwTl+uVo4ABeRlRjDwAU0HHy8irqLaB hhefesto@olimpo"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBAolzCtF1t8rPKSRzvREQPBUjxRAi5medog8Ebi0n/G hhefesto@delfos"
  ];
}
