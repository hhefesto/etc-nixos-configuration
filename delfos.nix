{ lib, pkgs, ... }:
{
  imports = [ ./hardware-configuration-delfos.nix ];

  networking.hostName = "delfos";

  # Dynamic time zone for travel: IP-based via tzupdate.
  # Triggered (a) at boot after network is up, (b) on every NM connection up.
  time.timeZone = lib.mkForce null;

  systemd.services.tzupdate = {
    description = "Update system timezone from IP geolocation";
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      # tzupdate 3.1.0 unlinks targets before symlinking; ENOENT on first run.
      ExecStartPre = pkgs.writeShellScript "tzupdate-ensure-targets" ''
        [ -e /etc/localtime ] || ${pkgs.coreutils}/bin/ln -sfn ${pkgs.tzdata}/share/zoneinfo/UTC /etc/localtime
        [ -e /etc/timezone ]  || ${pkgs.coreutils}/bin/touch /etc/timezone
      '';
      ExecStart = "${pkgs.tzupdate}/bin/tzupdate --always-write-debian-timezone -z ${pkgs.tzdata}/share/zoneinfo";
    };
  };

  networking.networkmanager.dispatcherScripts = [{
    type = "basic";
    source = pkgs.writeShellScript "tzupdate-on-nm-up" ''
      status=$2
      case "$status" in
        up|vpn-up|dhcp4-change|dhcp6-change)
          ${pkgs.systemd}/bin/systemctl start --no-block tzupdate.service
          ;;
      esac
    '';
  }];

  # --- LAN binary-cache: delfos <-> olimpo over ssh-ng ---------------------

  # Pull from olimpo's store.
  nix.settings.substituters = [
    "ssh-ng://nix-ssh@olimpo-nix-cache"
  ];
  nix.settings.trusted-substituters = [
    "ssh-ng://nix-ssh@olimpo-nix-cache"
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

  # nix.sshServe runs `nix-daemon --stdio` as the `nix-ssh` user.
  # allowed-users is restricted in configuration-core.nix, so re-grant
  # nix-ssh explicitly here (list-merges with the core values).
  nix.settings.allowed-users = [ "nix-ssh" ];
  nix.settings.trusted-users = [ "nix-ssh" ];

  # Pre-seed olimpo's host key so root's ssh client doesn't prompt.
  programs.ssh.knownHosts."olimpo-nix-cache" = {
    hostNames = [ "olimpo-nix-cache" "192.168.1.134" ];
    publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIP5EUe2fiscGEdLFXkTfxPLRmHuRBwqCbHcFSabqVWN1";
  };

  programs.ssh.extraConfig = ''
    Host olimpo-nix-cache
      HostName 192.168.1.134
      User nix-ssh
      IdentityFile /root/.ssh/id_ed25519
      IdentitiesOnly yes
      BatchMode yes
      PasswordAuthentication no
      KbdInteractiveAuthentication no
      ConnectTimeout 3
  '';
}
