{ ... }:
{
  imports = [ ./hardware-configuration-xty.nix ];

  networking.hostName = "xty";
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

  security.sudo.wheelNeedsPassword = false;

  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJcDIsto/6GS7XwTl+uVo4ABeRlRjDwAU0HHy8irqLaB hhefesto@olimpo"
  ];
}
