{ config, pkgs, ... }:

{
  home = {
    username = "hhefesto";
    homeDirectory = "/home/hhefesto";
    stateVersion = "22.11";
    # sessionPath = [ "${config.xdg.configHome}/emacs/bin" ];
    # sessionVariables = {
    #   DOOMDIR = "${config.xdg.configHome}/doom-config";
    #   DOOMLOCALDIR = "${config.xdg.configHome}/doom-local";
    # };
    # packages = with pkgs; [
    #   # DOOM Emacs dependencies
    #   binutils
    #   (ripgrep.override { withPCRE2 = true; })
    #   gnutls
    #   fd
    #   imagemagick
    #   zstd
    #   nodePackages.javascript-typescript-langserver
    #   sqlite
    #   editorconfig-core-c
    #   emacs-all-the-icons-fonts
    # ];
  };

#   xdg = {
#     enable = true;
#     configFile = {
#       "doom-config/config.el".text = '''
#         ;;;     $DOOMDIR/config.el -*- lexical-binding: t; -*-
#       ''';
#       "doom-config/init.el".text = '''
#         (doom! :input
#                ;;chinese
#                ;;japanese
#       ''';
#       "doom-config/packages.el".text = '''
#         (package! flycheck)
#       ''';
#       "EMACS" = {
#         source = builtins.fetchGit "https://github.com/hlissner/doom-emacs";
#         onChange = "${pkgs.writeShellScript "doom-change" ''
#           export DOOMDIR="${config.home.sessionVariables.DOOMDIR}"
#           export DOOMLOCALDIR="${config.home.sessionVariables.DOOMLOCALDIR}"
#           if [ ! -d "$DOOMLOCALDIR" ]; then
#             ${config.xdg.configHome}/emacs/bin/doom -y install
#           else
#             ${config.xdg.configHome}/emacs/bin/doom -y sync -u
#           fi
#         ''}";
#       };
#     };
#   };

  programs.zsh = {
    enable = true;
    # shellInit = ''
    #   # ssh
    #   # export SSH_KEY_PATH="~/.ssh/dsa_id"
    #   export SSH_AUTH_SOCK=~/.ssh/ssh-agent.$HOSTNAME.sock

    #   # Verify if ssh-agent is running
    #   ssh-add -l 2>/dev/null >/dev/null

    #   # if it was running, ssh-add will use it and return 1 (no keys)
    #   # if it was not running, it will return 2, so we proceed to execute the ssh-agent
    #   # and tell it where to create the Unix  socket (SSH_AUTH_SOCK):

    #   if [ $? -ge 2 ]; then
    #      ssh-agent -a "$SSH_AUTH_SOCK" >/dev/null
    #   fi

    #   ssh-add ~/.ssh/xpsoasis-ed25519
    # '';
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
      sn = "sudo nixos-rebuild switch";
      gr = "grep -R --exclude='TAGS' --exclude-dir={.stack-work,dist-newstyle,result,result-2} -n";
      where = "pwd";
      nd = "nix develop";
    };
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
}
