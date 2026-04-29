{ pkgs, ... }:
{
  environment.systemPackages = [ pkgs.emacs ];
  environment.variables.EDITOR = "emacs";

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  boot.binfmt.emulatedSystems = [ "aarch64-linux" ];

  networking.enableIPv6 = false;
  time.timeZone = "America/Mexico_City";

  nixpkgs.config.allowUnfree = true;

  services.openssh.enable = true;
  services.sshd.enable = true;

  programs.zsh.enable = true;

  users.mutableUsers = false;
  users.users.root.initialHashedPassword = "$6$/RvS0Se.iCx$A0eA/8PzgMj.Ms9ohNamfu53c9S.zdG30hEmUHLjmWP0CaXTPVA6QxGIZ6fy.abkjSOTJMAq7fFL6LUBGs4BU0";
  users.users.hhefesto.initialHashedPassword = "$6$/RvS0Se.iCx$A0eA/8PzgMj.Ms9ohNamfu53c9S.zdG30hEmUHLjmWP0CaXTPVA6QxGIZ6fy.abkjSOTJMAq7fFL6LUBGs4BU0";

  users.extraUsers.hhefesto = {
    createHome = true;
    isNormalUser = true;
    home = "/home/hhefesto";
    description = "Daniel Herrera";
    extraGroups = [ "wheel" ];
    hashedPassword = "$6$/RvS0Se.iCx$A0eA/8PzgMj.Ms9ohNamfu53c9S.zdG30hEmUHLjmWP0CaXTPVA6QxGIZ6fy.abkjSOTJMAq7fFL6LUBGs4BU0";
    openssh.authorizedKeys.keys = [ "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJcDIsto/6GS7XwTl+uVo4ABeRlRjDwAU0HHy8irqLaB hhefesto@olimpo"
                                    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIH2Ttj29zyClCr8pSobzAIJVcsEuL4GsPY7+aiK5eaA1"
                                  ];
    shell = pkgs.zsh;
  };

  nix.settings.auto-optimise-store = true;
  nix.settings.allow-import-from-derivation = true;

  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 7d";
  };

  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  nix.extraOptions = ''
    keep-outputs = true
    keep-derivations = true
    accept-flake-config = true
    allow-import-from-derivation = true
  '';

  nix.settings.trusted-public-keys = [
    "telomare.cachix.org-1:H0qRjVstxtb9oyEPvDDpmPSLyJ9oViAsTgwR02ra6Dk="
    "ryantrinkle.com-1:JJiAKaRv9mWgpVAz8dwewnZe0AzzEAzPkagE9SP5NWI="
    "claude-code.cachix.org-1:Yexf2anu7utx8vwrze0za1weds+4dui2kvewee4fsrk="
  ];

  nix.settings.trusted-substituters = [
    "https://hercules-ci.cachix.org"
    "https://cache.nixos.org"
    "https://nixcache.reflex-frp.org"
    "https://telomare.cachix.org"
    "https://claude-code.cachix.org"
  ];

  nix.settings.substituters = [
    "https://hercules-ci.cachix.org"
    "https://telomare.cachix.org"
    "https://nixcache.reflex-frp.org"
    "https://claude-code.cachix.org"
  ];

  nix.settings.allowed-users = [ "@wheel" "hhefesto" ];
  nix.settings.trusted-users = [ "hhefesto" ];

  system.stateVersion = "25.11";
}
