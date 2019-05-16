# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
    ];

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "Olimpo"; # Define your hostname.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Select internationalisation properties.
  # i18n = {
  #   consoleFont = "Lat2-Terminus16";
  #   consoleKeyMap = "us";
  #   defaultLocale = "en_US.UTF-8";
  # };

  # Set your time zone.
  time.timeZone = "America/Mexico_City";

  # environment.variables = {
  #   TERMINAL = [ "st" ];
  #   OH_MY_ZSH = [ "${pkgs.oh-my-zsh}/share/oh-my-zsh" ];
  # };
  # List packages installed in system profile. To search, run:
  # $ nix search wget
  nixpkgs.config.allowUnfree = true;
  # nixpkgs.config = {
  #   allowUnfree = true;
  #   st.conf = builtins.readFile /home/hhefesto/src/st/config.def.h;
  # };


  # nixpkgs.overlays = [ (self: super: {
  #   st = super.st.override {
  #     patches = builtins.map super.fetchurl [
  #         # { url = "http://st.suckless.org/patches/st-no_bold_colors-20160727-308bfbf.diff";
  #         #   sha256 = "2e8cdbeaaa79ed067ffcfdcf4c5f09fb5c8c984906cde97226d4dd219dda39dc";
  #         # }
  #         # { url = "http://st.suckless.org/patches/st-solarized-both-20160727-308bfbf.diff";
  #         #   sha256 = "b7b25ba01b7ae87ec201ebbb1bf82742d5979788ecc6773a356eebe7d90a9703";
  #         # }
  #         # { url = "https://raw.githubusercontent.com/hhefesto/dotfiles/master/patches/st-scrollback-20190331-21367a0.diff";
  #         #   sha1 = "fc5140eb0cc74636e5a0f5cd629e3cfbd10c9ed7";
  #         # }
  #         # { url = "https://raw.githubusercontent.com/hhefesto/dotfiles/master/patches/st-solarized-both-0.8.1.diff";
  #         #   sha256 = "be003c27ad96ff82a90353455fa6dbd50b5030ecbb751b6ed7283ed0023e683d";
  #         # }
  #         { url = "https://st.suckless.org/patches/scrollback/st-scrollback-0.7.diff";
  #           sha256 = "f721b15a5aa8d77a4b6b44713131c5f55e7fca04006bc0a3cb140ed51c14cfb6";
  #         }
  #         # { url = "https://st.suckless.org/patches/scrollback/st-scrollback-mouse-0.8.diff";
  #         #   sha1 = "46e92d9d3f6fd1e4f08ed99bda16b232a1687407";
  #         # }
  #         # { url = "https://st.suckless.org/patches/scrollback/st-scrollback-mouse-altscreen-0.8.diff";
  #         #   sha1 = "d3329413998c5f3feaa7764db36269bf7b3d1334";
  #         # }
  #       ];
  #   };
  # }) ];
  environment.systemPackages = with pkgs; [
    # (import (fetchGit "https://github.com/haslersn/fish-nix-shell"))
    wget
    vim
    emacs
    tmux
    curl
    gist
    git
    scrot
    xclip
    feh
    firefox
    dmenu
    tabbed
    st
    haskellPackages.xmobar
    ranger
    # fish
    obs-studio
    qbittorrent
    libreoffice
    vlc
    dropbox-cli
    gnome3.nautilus
    # zsh
    # oh-my-zsh
    calibre
    taffybar
    sshpass
    gimp
    gparted
    octave
    htop
    stack
    postgresql_11
    nixops
    # skypeforlinux
    google-chrome
    # spotify # this loops `nixos-rebuild switch` 
    stack2nix
    ghc
  ];

  systemd.user.services.dropbox = {
    restartIfChanged = true;
    enable = true;
    serviceConfig = {
      ExecStart = "${pkgs.dropbox}/bin/dropbox";
      PassEnvironment = "DISPLAY";
    };
  };

  
  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = { enable = true; enableSSHSupport = true; };
  # programs.fish.enable = true;
  # programs.fish.promptInit = ''
  #   fish-nix-shell --info-right | source
  # '';
  # programs.zsh.interactiveShellInit = ''
  #   export ZSH=${pkgs.oh-my-zsh}/share/oh-my-zsh/

  #   # Customize your oh-my-zsh options here
  #   ZSH_THEME="bira"
  #   plugins=(git dnf sudo colorize extract history postgres)

  #   source $ZSH/oh-my-zsh.sh
  # '';
  # programs.zsh.promptInit = ""; # Clear this to avoid a conflict with oh-my-zsh
  
  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  # services.openssh.enable = true;

  # Open ports in the firewall.
  networking.firewall.allowedTCPPorts = [ 3000 5432 ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # Enable CUPS to print documents.
  # services.printing.enable = true;

  # Enable sound.
  # sound.enable = true;
  # hardware.pulseaudio.enable = true;

  # Enable the X11 windowing system.
  # services.xserver.enable = true;
  # services.xserver.layout = "us";
  # services.xserver.xkbOptions = "eurosign:e";
  services = {
    openssh.enable = true;
    xserver = {
      enable = true;
      layout = "us";
      displayManager.gdm.enable = true;
      desktopManager = {
        gnome3.enable = true;
        default = "gnome3";
      };
      windowManager.default = "xmonad";
      windowManager.xmonad = {
        enable = true;
        enableContribAndExtras = true;
        extraPackages = haskellPackages:[
          haskellPackages.xmonad-contrib
          haskellPackages.xmonad-extras
          haskellPackages.xmonad
        ];
      };
    };
    # postgresql = {
    #   enable = true;
    #   package = pkgs.postgresql_11;
    #   enableTCPIP = true;
    #   authentication = pkgs.lib.mkOverride 10 ''
    #     local all all trust
    #     host all all ::1/128 trust
    #   '';
    #   initialScript = pkgs.writeText "backend-initScript" ''
    #     CREATE ROLE analyzer WITH LOGIN PASSWORD 'anapass' CREATEDB;
    #     CREATE DATABASE aanalyzer_yesod;
    #     GRANT ALL PRIVILEGES ON DATABASE analyzer TO aanalyzer_yesod;
    # '';
    # };
  };

 # virtualisation.virtualbox.host.enable = true;
  
  # Enable touchpad support.
  # services.xserver.libinput.enable = true;

  # Enable the KDE Desktop Environment.
  # services.xserver.displayManager.sddm.enable = true;
  # services.xserver.desktopManager.plasma5.enable = true;

  # Define a user account. Don't forget to set a password with ‘passwd’.
  # users.users.jane = {
  #   isNormalUser = true;
  #   extraGroups = [ "wheel" ]; # Enable ‘sudo’ for the user.
  # };
  

  users.mutableUsers = false;
#  users.users.root.initialHashedPassword = "$6$somesaltplease$DsmSOQw5RtwC053qvLM/APD.vgolHe/.mrYOSOTJZTsS2brm0/8ZrQgCaEFczipgiPzY/chyqWbk5HG/GGhFH.";
  users.users.root.initialHashedPassword = "$6$n4g4i9VHr52IqYY$7DMpovz3Z91gSpnfrGPPw.s1DfbdpyfJnwjv7on4G1gtFCOr0PaWOcJUHREuGzZwKZORnx7SOFAqgyehW.nxz/";
  users.users.hhefesto.initialHashedPassword = "$6$n4g4i9VHr52IqYY$7DMpovz3Z91gSpnfrGPPw.s1DfbdpyfJnwjv7on4G1gtFCOr0PaWOcJUHREuGzZwKZORnx7SOFAqgyehW.nxz/"; # this may be redundant
  users.extraUsers.hhefesto = {
    createHome = true;
    isNormalUser = true;
    home = "/home/hhefesto";
    description = "Daniel Herrera";
    extraGroups = [ "wheel" "networkmanager" ];
    hashedPassword = "$6$n4g4i9VHr52IqYY$7DMpovz3Z91gSpnfrGPPw.s1DfbdpyfJnwjv7on4G1gtFCOr0PaWOcJUHREuGzZwKZORnx7SOFAqgyehW.nxz/";
#    hashedPassword = "$6$somesaltplease$DsmSOQw5RtwC053qvLM/APD.vgolHe/.mrYOSOTJZTsS2brm0/8ZrQgCaEFczipgiPzY/chyqWbk5HG/GGhFH.";
    shell = "/run/current-system/sw/bin/bash";
  };

# This value determines the NixOS release with which your system is to be
  # compatible, in order to avoid breaking some software such as database
  # servers. You should change this only after NixOS release notes say you
  # should.
  system.stateVersion = "19.03"; # Did you read the comment?

}
