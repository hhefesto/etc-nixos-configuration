{ config, pkgs, lib, myAgda, ... }:
let
  doomRepoUrl = "https://github.com/doomemacs/doomemacs";
  doomRevision = "master";  # or specific commit hash
  agdaModePath = import ./get-agda-mode-path.nix { inherit myAgda pkgs; };
in {
  home.sessionVariables = {
    # Change this timestamp to force a rebuild
    LAST_REBUILD = "2025-03-13";
  };
  home = {
    username = "moper";
    homeDirectory = "/home/moper";
    stateVersion = "22.11";
  };
  home.file.".doom.d/agda-mode-path.el" = {
    text = ''
      (setq agda2-mode-path "${agdaModePath}")
    '';
  };
  home.file = {
    ".doom.d" = {
      source = ./doom.d;
      recursive = true;
    };
  };
  home.activation = {
    installDoomEmacs = lib.hm.dag.entryAfter ["linkGeneration" "installPackages" "copyFonts" "postActivation"] ''
      echo "Checking for existing doom emacs installation"
      if [ ! -d "$HOME/.emacs.d/bin" ]; then
        export PATH="${lib.makeBinPath [ pkgs.emacs pkgs.git ]}:$PATH"
	
        rm -rf $HOME/.emacs.d

      echo "cloning doom emacs:"
      ${pkgs.git}/bin/git clone --depth=1 --single-branch "${doomRepoUrl}" "$HOME/.emacs.d"

      echo "installing doom emacs:"
            ("$HOME/.emacs.d/bin/doom" install --force) 2>&1 | tee /tmp/doom-install.log || {
              echo "Failed to install Doom Emacs. Check /tmp/doom-install.log for details"
              echo "Last few lines of the log:"
              tail -n 20 /tmp/doom-install.log
              exit 1
            }
          fi
        '';
  };
  
  programs.zsh = {
    enable = true;
    shellAliases = {
      cat = "bat";
      _cat = "cat";
      crun = "cabal new-run";
      ct = "cabal new-test";
      cr = "cabal new-repl";
      cb = "cabal new-build";
      tr = "cd ~/src/telomare && cabal new-run telomare-mini-repl -- --haskell";
      telomare-repl = "cd ~/src/telomare && cabal new-run telomare-mini-repl -- --haskell";
      gs = "git status";
      ga = "git add -A";
      gd = "git diff";
      gc = "git commit -am";
      gcs = "git commit -am \"squash\"";
      gbs = "git --no-pager branch --sort -committerdate";
      sendmail = "/run/current-system/sw/bin/msmtp --debug --from=default --file=/etc/msmtp/laurus -t";
      xclip = "xclip -selection c";
      please = "sudo";
      n = "nix-shell shell.nix";
      sn = "sudo nixos-rebuild -v switch";
      gr = "grep -R --exclude='TAGS' --exclude-dir={.stack-work,dist-newstyle,result,result-2} -n";
      where = "pwd";
      nd = "nix develop";
    };
  };

  # Add the doom binary to your PATH
  home.sessionPath = [ "$HOME/.emacs.d/bin"
                     ];

  programs.emacs.enable = true;

  programs.direnv = {
    enable = true;
    enableZshIntegration = true;
    nix-direnv.enable = true;
  };

  programs.git = {
    enable = true;
    userEmail = "mopertico@rdataa.com";
    userName = "moper";

    extraConfig = {
      core = {
        editor = "emacs";
      };
      merge = {
        conflictstyle = "diff3";
      };
    };

    aliases = {
      lg = "!git lg1 --simplify-by-decoration";
      lg1 = "!git lg1-specific --all --simplify-by-decoration";
      lg2 = "!git lg2-specific --all --simplify-by-decoration";
      lg3 = "!git lg3-specific --all --simplify-by-decoration";

      lg1-specific = "log --graph --abbrev-commit --decorate --format=format:\'%C(bold blue)%h%C(reset) - %C(bold green)(%ar)%C(reset) %C(white)%s%C(reset) %C(dim white)- %an%C(reset)%C(auto)%d%C(reset)\'";
      lg2-specific = "log --graph --abbrev-commit --decorate --format=format:\'%C(bold blue)%h%C(reset) - %C(bold cyan)%aD%C(reset) %C(bold green)(%ar)%C(reset)%C(auto)%d%C(reset)%n\'\'          %C(white)%s%C(reset) %C(dim white)- %an%C(reset)\'";
      lg3-specific = "log --graph --abbrev-commit --decorate --format=format:\'%C(bold blue)%h%C(reset) - %C(bold cyan)%aD%C(reset) %C(bold green)(%ar)%C(reset) %C(bold cyan)(committed: %cD)%C(reset) %C(auto)%d%C(reset)%n\'\'          %C(white)%s%C(reset)%n\'\'          %C(dim white)- %an <%ae> %C(reset) %C(dim white)(committer: %cn <%ce>)%C(reset)\'";

      # ATTENTION: All aliases prefixed with ! run in /bin/sh make sure you use sh syntax, not bash/zsh or whatever
      # recentb = "!r() { refbranch=$1 count=$2; git for-each-ref --sort=-committerdate refs/heads --format=\'%(refname:short)|%(HEAD)%(color:yellow)%(refname:short)|%(color:bold green)%(committerdate:relative)|%(color:blue)%(subject)|%(color:magenta)%(authorname)%(color:reset)\' --color=always --count=${count:-20} | while read line; do branch=$(echo \"$line\" | awk \'BEGIN { FS = \"|\" }; { print $1 }\' | tr -d \'*\'); ahead=$(git rev-list --count \"${refbranch:-master}..${branch}\"); behind=$(git rev-list --count \"${branch}..${refbranch:-master}\"); colorline=$(echo \"$line\" | sed \'s/^[^|]*|//\'); echo \"$ahead|$behind|$colorline\" | awk -F\'|\' -vOFS=\'|\' \'{$5=substr($5,1,70)}1\' ; done | ( echo \"ahead|behind||branch|lastcommit|message|author\\n\" && cat) | column -ts\'|\';}; r";
    };

  };
  programs.xmobar.enable = true;
  programs.xmobar.extraConfig = pkgs.lib.readFile ./xmobarrc;
  programs.home-manager.enable = true;

  home.packages = with pkgs; [
    gnome-themes-extra
    adw-gtk3  # Add this for better Adwaita theme support
  ];

  gtk = {
    enable = true;

    theme = {
      name = "adw-gtk3-dark";  # Using adw-gtk3 instead of plain Adwaita
      package = pkgs.adw-gtk3;
    };

    gtk3.extraConfig = {
      gtk-application-prefer-dark-theme = true;
    };

    gtk4.extraConfig = {
      gtk-application-prefer-dark-theme = true;
    };
  };

  dconf.settings = {
    "org/gnome/desktop/interface" = {
      color-scheme = "prefer-dark";
      gtk-theme = "adw-gtk3-dark";
      enable-hot-corners = false;
    };

    # These additional settings help ensure dark mode consistency
    "org/gnome/shell/extensions/user-theme" = {
      name = "adw-gtk3-dark";
    };

    "org/gtk/settings/file-chooser" = {
      theme-variant = "dark";
    };

    "org/gnome/nautilus/preferences" = {
      theme-variant = "dark";
    };
  };
}
