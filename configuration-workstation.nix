{ pkgs, lib, inputs, ... }:
{
  nixpkgs.overlays = [
    inputs.claude-code-nix.overlays.default
    (final: prev: {
      bun = inputs.opencode.inputs.nixpkgs.legacyPackages.${prev.stdenv.hostPlatform.system}.bun;
    })
    inputs.opencode.overlays.default
  ];

  environment.systemPackages = with pkgs; [
    python3
    openssl
    bind
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

    shellAliases = {
      cat = "bat";
      _cat = "cat";
      gs = "git status";
      ga = "git add -A";
      gd = "git diff";
      gc = "git commit -am";
      gcs = "git commit -am \"squash\"";
      gbs = "git --no-pager branch --sort -committerdate";
      xclip = "xclip -selection c";
      please = "sudo";
      n = "nix -Lv";
      nd = "nix -Lv develop -c zsh";
      sn = "sudo nixos-rebuild -v switch --flake ~/src/etc-nixos-configuration";
      gr = "grep -R --exclude='TAGS' --exclude-dir={.stack-work,dist-newstyle,result,result-2} -n";
      where = "pwd";
    };

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
      RPROMPT=${"'"}''${RPROMPT:+$RPROMPT  }%F{244}[%D{%H:%M:%S}]%f${"'"}
    '';

    promptInit = ''
      any-nix-shell zsh --info-right | source /dev/stdin
    '';
  };

  users.users.root.shell = pkgs.zsh;

  users.extraUsers.hhefesto.extraGroups = lib.mkAfter [ "docker" ];
  virtualisation.docker.enable = true;
}
