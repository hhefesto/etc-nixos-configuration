{ pkgs, lib, inputs, ... }:
{
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  boot.binfmt.emulatedSystems = [ "aarch64-linux" ];

  networking.enableIPv6 = false;
  time.timeZone = "America/Mexico_City";

  nixpkgs.config.allowUnfree = true;
  nixpkgs.overlays = [
    inputs.claude-code-nix.overlays.default
    (final: prev: {
      bun = inputs.opencode.inputs.nixpkgs.legacyPackages.${prev.stdenv.hostPlatform.system}.bun;
    })
    inputs.opencode.overlays.default
    (final: prev: {
      opencode = prev.opencode.overrideAttrs (old: {
        postConfigure = (old.postConfigure or "") + ''
          patchShebangs node_modules
          patchShebangs packages

          if [ -e packages/app/node_modules/.bin/vite ]; then
            vite_target=$(readlink -f packages/app/node_modules/.bin/vite || true)
            if [ -n "$vite_target" ]; then
              substituteInPlace "$vite_target" --replace /usr/bin/env ${prev.coreutils}/bin/env
            else
              substituteInPlace packages/app/node_modules/.bin/vite --replace /usr/bin/env ${prev.coreutils}/bin/env
            fi
          fi
        '';
      });
    })
  ];

  environment.systemPackages = with pkgs; [
    opencode
    claude-code
    tesseract
    poppler-utils
    sd
    fd
    cmatrix
    bat
    jq
    zip
    rename
    parallel
    direnv
    nix-direnv
    ripgrep
    any-nix-shell
    wget
    vim
    emacs
    tmux
    curl
    gh
    gist
    git
    lambda-mod-zsh-theme
    oh-my-zsh
    zsh
    ranger
    htop
    nix-prefetch-git
    nixd
    hunspell
    hunspellDicts.es-any
    hunspellDicts.es-mx
    hunspellDicts.en-us
    (aspellWithDicts (dicts: with dicts; [ es en en-computers en-science ]))
    unrar
    unzip
    hack-font
    cachix
    tree
    gnumake
    zlib
    msmtp
    gmp
  ];

  environment.pathsToLink = [
    "/share/nix-direnv"
    "/share/zsh"
  ];

  systemd.user.services.home-manager-hhefesto.serviceConfig = {
    TimeoutStartSec = "20m";
    TimeoutStopSec = "20m";
    Nice = 19;
    IOSchedulingClass = "idle";
    IOSchedulingPriority = 7;
  };

  programs.nix-index.enableZshIntegration = true;

  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestions.enable = true;
    syntaxHighlighting.enable = true;
    ohMyZsh.enable = true;
    ohMyZsh.plugins = [ "git" "sudo" "colorize" "extract" "history" "postgres" ];
    ohMyZsh.theme = "intheloop";

    shellInit = ''
      if [[ -o interactive ]]; then
        ssh-add -l >/dev/null 2>&1
        if [ $? -eq 2 ]; then
          eval "$(ssh-agent -s)" >/dev/null
        fi

        ssh-add -q ~/.ssh/xpsoasis-ed25519
        ssh-add -q ~/.ssh/id_ed25519
      fi
    '';

    interactiveShellInit = ''
      save_aliases=$(alias -L)
      eval $save_aliases; unset save_aliases
    '';

    promptInit = ''
      any-nix-shell zsh --info-right | source /dev/stdin
    '';
  };

  services.openssh.enable = true;
  services.sshd.enable = true;

  users.mutableUsers = false;
  users.users.root.initialHashedPassword = "$6$/RvS0Se.iCx$A0eA/8PzgMj.Ms9ohNamfu53c9S.zdG30hEmUHLjmWP0CaXTPVA6QxGIZ6fy.abkjSOTJMAq7fFL6LUBGs4BU0";
  users.users.hhefesto.initialHashedPassword = "$6$/RvS0Se.iCx$A0eA/8PzgMj.Ms9ohNamfu53c9S.zdG30hEmUHLjmWP0CaXTPVA6QxGIZ6fy.abkjSOTJMAq7fFL6LUBGs4BU0";

  users.extraUsers.hhefesto = {
    createHome = true;
    isNormalUser = true;
    home = "/home/hhefesto";
    description = "Daniel Herrera";
    extraGroups = [ "wheel" "docker" ];
    hashedPassword = "$6$/RvS0Se.iCx$A0eA/8PzgMj.Ms9ohNamfu53c9S.zdG30hEmUHLjmWP0CaXTPVA6QxGIZ6fy.abkjSOTJMAq7fFL6LUBGs4BU0";
    openssh.authorizedKeys.keys = [ "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJcDIsto/6GS7XwTl+uVo4ABeRlRjDwAU0HHy8irqLaB hhefesto@olimpo" ];
    shell = pkgs.zsh;
  };

  virtualisation.docker.enable = true;

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
    "hydra.iohk.io:f/Ea+s+dFdN+3Y/G+FDgSq+a5NEWhJGzdjvKNGv0/EQ="
    "telomare.cachix.org-1:H0qRjVstxtb9oyEPvDDpmPSLyJ9oViAsTgwR02ra6Dk="
    "ryantrinkle.com-1:JJiAKaRv9mWgpVAz8dwewnZe0AzzEAzPkagE9SP5NWI="
    "claude-code.cachix.org-1:YeXf2aNu7UTX8Vwrze0za1WEDS+4DuI2kVeWEE4fsRk="
  ];

  nix.settings.trusted-substituters = [
    "https://nixcache.reflex-frp.org"
    "https://cache.iog.io"
    "https://telomare.cachix.org"
    "https://claude-code.cachix.org"
  ];

  nix.settings.substituters = [
    "https://telomare.cachix.org"
    "https://nixcache.reflex-frp.org"
    "https://cache.iog.io"
    "https://claude-code.cachix.org"
  ];

  nix.settings.allowed-users = [ "@wheel" "hhefesto" ];
  nix.settings.trusted-users = [ "hhefesto" ];

  system.stateVersion = "25.05";
}
