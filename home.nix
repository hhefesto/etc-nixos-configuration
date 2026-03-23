{ config, pkgs, lib, spacemacs, ... }:
{
  home = {
    username = "hhefesto";
    homeDirectory = "/home/hhefesto";
    stateVersion = "22.11";
  };
  home.activation = {
    installSpacemacs = lib.hm.dag.entryAfter ["writeBoundary"] ''
      if [ ! -f "$HOME/.spacemacs" ]; then
        cp ${./spacemacs} "$HOME/.spacemacs"
        chmod 644 "$HOME/.spacemacs"
      fi
      if [ ! -d "$HOME/.emacs.d" ]; then
        cp -r ${spacemacs} "$HOME/.emacs.d"
        chmod -R u+w "$HOME/.emacs.d/"
      fi
    '';
  };

  programs.zsh = {
    enable = true;
    shellAliases = {
      id = "echo change";
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
  };

  # Add the doom binary to your PATH
  # home.sessionPath = [ "$HOME/.emacs.d/bin"
  #                    ];

  programs.emacs = {
    enable = true;
    extraPackages = epkgs: [
      epkgs.spinner
      epkgs.paradox
      epkgs.lsp-mode
      epkgs.lsp-ui
      epkgs.lsp-treemacs
      epkgs.helm-lsp
      epkgs.origami
    ];
  };

  programs.direnv = {
    enable = true;
    enableZshIntegration = true;
    nix-direnv.enable = true;
  };

  programs.git = {
    enable = true;
    userEmail = "hhefesto@rdataa.com";
    userName = "hhefesto";

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
