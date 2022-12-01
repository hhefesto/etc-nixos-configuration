{ config, pkgs, ... }:

{
  # List packages installed in system profile. To search by name, run:
  # $ nix-env -qaP | grep wget
  environment.systemPackages = with pkgs;
    [ vim
      emacs
      git
      cachix
      ripgrep
      fd
      gcc
      hack-font
      zsh
      teams
      oh-my-zsh
      lambda-mod-zsh-theme
      direnv
      any-nix-shell
      bat
    ];

  fonts.fonts = with pkgs; [
    hack-font
  ];

  time.timeZone = "America/Mexico_City";


  # Use a custom configuration.nix location.
  # $ darwin-rebuild switch -I darwin-config=$HOME/.config/nixpkgs/darwin/configuration.nix
  # environment.darwinConfig = "$HOME/.config/nixpkgs/darwin/configuration.nix";

  nixpkgs.config.allowUnfree = true;

  environment.interactiveShellInit = ''
    # alias fn='cabal repl' #TODO:Fix
    # alias 'cabal run'='cabal new-run' #TODO:Fix
    # alias 'cabal build'='cabal new-build' #TODO:Fix
    alias cat='bat'
    alias _cat='cat'
    alias crun='cabal new-run'
    alias ct='cabal new-test'
    alias cr='cabal new-repl'
    alias cb='cabal new-build'
    alias tr='cd ~/src/telomare && cabal new-run telomare-mini-repl -- --haskell'
    alias telomare-repl='cd ~/src/telomare && cabal new-run telomare-mini-repl -- --haskell'
    alias gs='git status'
    alias ga='git add -A'
    alias gd='git diff'
    alias gc='git commit -am'
    alias gcs='git commit -am "squash"'
    alias gbs='git branch --sort=-committerdate'
    alias sendmail='/run/current-system/sw/bin/msmtp --debug --from=default --file=/etc/msmtp/laurus -t'
    alias xclip='xclip -selection c'
    alias please='sudo'
    alias n='nix-shell shell.nix'
    # alias nod='nixops deploy -d laurus-nobilis-gce'
    alias sn='sudo nixos-rebuild switch'
    alias gr='grep -R --exclude='TAGS' --exclude-dir={.stack-work,dist-newstyle,result,result-2} -n'
    alias where='pwd'
    alias nd='nix develop'
  '';

  programs.zsh = {
    enable = true;
    enableCompletion = true;
    interactiveShellInit = ''
      # z - jump around
      # source ${pkgs.fetchurl {url = "https://github.com/rupa/z/raw/2ebe419ae18316c5597dd5fb84b5d8595ff1dde9/z.sh"; sha256 = "0ywpgk3ksjq7g30bqbhl9znz3jh6jfg8lxnbdbaiipzgsy41vi10";}}
      save_aliases=$(alias -L)
      export ZSH=${pkgs.oh-my-zsh}/share/oh-my-zsh
      export ZSH_THEME="bira" #"lambda"
      plugins=(git sudo colorize extract history postgres)
      source $ZSH/oh-my-zsh.sh
      eval $save_aliases; unset save_aliases
    '';
    promptInit = ''
      any-nix-shell zsh --info-right | source /dev/stdin
  '';
  };

  nix.settings.allowed-users = [ "@wheel" "danielherrera" ];
  nix.settings.trusted-users = [ "root" "danielherrera" ];

  # Auto upgrade nix package and the daemon service.
  services.nix-daemon.enable = true;

  # For nix flakes
  nix.package = pkgs.nixUnstable;
  nix.extraOptions = ''
    experimental-features = nix-command flakes
    keep-outputs = true
    keep-derivations = true
  '';

  # Used for backwards compatibility, please read the changelog before changing.
  # $ darwin-rebuild changelog
  system.stateVersion = 4;
}
