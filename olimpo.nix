{ ... }:
{
  imports = [ ./hardware-configuration-olimpo.nix ];

  networking.hostName = "olimpo";

  # --- LAN binary-cache: olimpo <-> delfos over ssh-ng ---------------------

  # Pull from delfos's store.
  nix.settings.substituters = [
    "ssh-ng://nix-ssh@192.168.1.139"
  ];
  nix.settings.trusted-substituters = [
    "ssh-ng://nix-ssh@192.168.1.139"
  ];
  nix.settings.trusted-public-keys = [
    # Contents of /etc/nix/cache-pub-key.pem on delfos.
    "delfos:hcd36Z1XMujbH2BoY1Xv7b+p5GbcMOCy/Of6qCxWmjYPewhiGuRwlRvs7TX6v3igPnQ1Vi85LTYeDaile7tobA=="
  ];

  # Serve olimpo's store to delfos. Authorize delfos's root key.
  nix.sshServe = {
    enable   = true;
    protocol = "ssh-ng";
    keys = [
      # Contents of /root/.ssh/id_ed25519.pub on delfos.
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGPjABQfwQ+vpgGqO6zsWNsG40ZFc55Z3zZQPA+3F4V9 root@delfos"
    ];
  };

  # Sign every path olimpo serves so delfos accepts the signature.
  nix.settings.secret-key-files = [ "/etc/nix/cache-priv-key.pem" ];

  # Pre-seed delfos's host key so root's ssh client doesn't prompt.
  programs.ssh.knownHosts."192.168.1.139" = {
    publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIINM3/adCok24i8fl600FBto4A/thxXaKpDu5B3ec3QT";
  };
}
