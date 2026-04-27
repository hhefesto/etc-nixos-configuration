{ ... }:
{
  imports = [ ./hardware-configuration-delfos.nix ];

  networking.hostName = "delfos";

  # --- LAN binary-cache: delfos <-> olimpo over ssh-ng ---------------------

  # Pull from olimpo's store.
  nix.settings.substituters = [
    "ssh-ng://nix-ssh@192.168.1.134"
  ];
  nix.settings.trusted-substituters = [
    "ssh-ng://nix-ssh@192.168.1.134"
  ];
  nix.settings.trusted-public-keys = [
    # Contents of /etc/nix/cache-pub-key.pem on olimpo.
    "olimpo:TF6AYCr4dpXzfG9KXGRaRxWuqo6lnyXABLhIc5wVnD0="
  ];

  # Serve delfos's store to olimpo. Authorize olimpo's root key.
  nix.sshServe = {
    enable   = true;
    protocol = "ssh-ng";
    keys = [
      # Contents of /root/.ssh/id_ed25519.pub on olimpo.
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPffFDK3fp6W/Z9PXCT7ZK+fSUB40JW/6Ezi9GwkiT9R root@olimpo"
    ];
  };

  # Sign every path delfos serves so olimpo accepts the signature.
  nix.settings.secret-key-files = [ "/etc/nix/cache-priv-key.pem" ];

  # Pre-seed olimpo's host key so root's ssh client doesn't prompt.
  programs.ssh.knownHosts."192.168.1.134" = {
    publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIP5EUe2fiscGEdLFXkTfxPLRmHuRBwqCbHcFSabqVWN1";
  };
}
