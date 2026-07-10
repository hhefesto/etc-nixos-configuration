{ pkgs, ... }:
{
  imports = [ ./hardware-configuration-olimpo.nix ];

  networking.hostName = "olimpo";

  # OpenCL for the RX 580 (Polaris/gfx803). ROCm dropped this GPU, so the
  # compute path is Mesa's rusticl; RUSTICL_ENABLE exposes the radeonsi
  # driver as an OpenCL device. Consumed by the Futhark GPU training
  # backend in ~/src/modArTransformer (see ELLIOTT-LLM.md there).
  hardware.graphics = {
    enable = true;
    extraPackages = [ pkgs.mesa.opencl ];
  };
  environment.variables.RUSTICL_ENABLE = "radeonsi";

  # Relax amdgpu's job watchdog from ~10 s to 60 s so training kernels can
  # run in larger launches (see TRAINING-GUIDE.md Lesson 10).
  # Tradeoff: a genuinely hung GPU job stalls the desktop up to 60 s
  # before soft recovery instead of 10 s.
  boot.kernelParams = [ "amdgpu.lockup_timeout=60000" ];

  # --- LAN binary-cache: olimpo <-> delfos over ssh-ng ---------------------

  # Pull from delfos's store.
  nix.settings.substituters = [
    "ssh-ng://nix-ssh@delfos-nix-cache"
  ];
  nix.settings.trusted-substituters = [
    "ssh-ng://nix-ssh@delfos-nix-cache"
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

  # nix.sshServe runs `nix-daemon --stdio` as the `nix-ssh` user.
  # allowed-users is restricted in configuration-core.nix, so re-grant
  # nix-ssh explicitly here (list-merges with the core values).
  nix.settings.allowed-users = [ "nix-ssh" ];
  nix.settings.trusted-users = [ "nix-ssh" ];

  # Pre-seed delfos's host key so root's ssh client doesn't prompt.
  programs.ssh.knownHosts."delfos-nix-cache" = {
    hostNames = [ "delfos-nix-cache" "192.168.3.6" ];
    publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIINM3/adCok24i8fl600FBto4A/thxXaKpDu5B3ec3QT";
  };

  programs.ssh.extraConfig = ''
    Host delfos-nix-cache
      HostName 192.168.3.6
      User nix-ssh
      IdentityFile /root/.ssh/id_ed25519
      IdentitiesOnly yes
      BatchMode yes
      PasswordAuthentication no
      KbdInteractiveAuthentication no
      ConnectTimeout 3
  '';
}
