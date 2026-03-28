{
  description = "hhefesto's system configuration";

  inputs = {
    determinate.url = "https://flakehub.com/f/DeterminateSystems/determinate/*";
    nixpkgs.url = "https://flakehub.com/f/NixOS/nixpkgs/*";
    flake-parts.url = "github:hercules-ci/flake-parts";
    home-manager = {
      url = "github:nix-community/home-manager/release-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    agenix = {
      url = "github:ryantm/agenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    claude-code-nix.url = "github:sadjow/claude-code-nix";
    opencode.url = "github:anomalyco/opencode?ref=dev";
    spacemacs = {
      url = "github:syl20bnr/spacemacs";
      flake = false;
    };
  };

  outputs = inputs@{ self, flake-parts, nixpkgs, home-manager, claude-code-nix, opencode, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [ "x86_64-linux" ];

      flake = let
        system = "x86_64-linux";
        mkHost = { hostModule, xmobarrc, extraSpecialArgs ? {} }: nixpkgs.lib.nixosSystem {
          inherit system;
          modules = [
            hostModule
            ./configuration.nix
            # determinate.nixosModules.default
            home-manager.nixosModules.home-manager
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.users.hhefesto = import ./home.nix;
              home-manager.extraSpecialArgs = {
                spacemacs = inputs.spacemacs;
                inherit xmobarrc;
              };
            }
            {
              nixpkgs.overlays = [
                claude-code-nix.overlays.default
                (final: prev: {
                  bun = opencode.inputs.nixpkgs.legacyPackages.${system}.bun;
                })
                opencode.overlays.default
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
            }
          ];
          specialArgs = { inherit inputs; } // extraSpecialArgs;
        };
      in {
        nixosConfigurations.delfos = mkHost {
          hostModule = ./delfos.nix;
          xmobarrc = ./xmobarrc-delfos;
          extraSpecialArgs = { xmonadShortenLength = 26; };
        };

        nixosConfigurations.olimpo = mkHost {
          hostModule = ./olimpo.nix;
          xmobarrc = ./xmobarrc-olimpo;
          extraSpecialArgs = { xmonadShortenLength = 50; };
        };
      };

      perSystem = { pkgs, ... }: {
        packages = let
          hosts = self.nixosConfigurations;
          entries = builtins.map (name: {
            inherit name;
            path = hosts.${name}.config.system.build.toplevel;
          }) (builtins.attrNames hosts);
        in {
          default = pkgs.linkFarm "all-hosts" entries;
          delfos = hosts.delfos.config.system.build.toplevel;
          olimpo = hosts.olimpo.config.system.build.toplevel;
        };
      };
    };
}
