{ pkgs, lib, inputs, ... }:
{
  nixpkgs.overlays = [
    inputs.claude-code-nix.overlays.default
    (final: prev: {
      bun = inputs.opencode.inputs.nixpkgs.legacyPackages.${prev.stdenv.hostPlatform.system}.bun;
    })
    inputs.opencode.overlays.default
    (final: prev: {
      opencode = prev.opencode.overrideAttrs (old: {
        patches = (old.patches or [ ]) ++ [
          (builtins.toFile "opencode-generate-without-prettier.patch" ''
            diff --git a/packages/opencode/src/cli/cmd/generate.ts b/packages/opencode/src/cli/cmd/generate.ts
            --- a/packages/opencode/src/cli/cmd/generate.ts
            +++ b/packages/opencode/src/cli/cmd/generate.ts
            @@ -30,17 +30,7 @@ export const GenerateCommand = {
                 }
                 const raw = JSON.stringify(specs, null, 2)

            -    // Format through prettier so output is byte-identical to committed file
            -    // regardless of whether ./script/format.ts runs afterward.
            -    const prettier = await import("prettier")
            -    const babel = await import("prettier/plugins/babel")
            -    const estree = await import("prettier/plugins/estree")
            -    const format = prettier.format ?? prettier.default?.format
            -    const json = await format(raw, {
            -      parser: "json",
            -      plugins: [babel.default ?? babel, estree.default ?? estree],
            -      printWidth: 120,
            -    })
            +    const json = raw

                 // Wait for stdout to finish writing before process.exit() is called
                 await new Promise<void>((resolve, reject) => {
          '')
        ];

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

  users.extraUsers.hhefesto.extraGroups = lib.mkAfter [ "docker" ];
  virtualisation.docker.enable = true;
}
