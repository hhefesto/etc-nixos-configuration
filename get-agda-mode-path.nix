{ myAgda, pkgs }:
pkgs.lib.readFile (pkgs.runCommand "agda-mode-location" {} ''
  dirname "$(${myAgda}/bin/agda-mode locate)" | tr -d '\n' > $out
'')
# To test in this flake's repl do:
# pkgs = inputs.nixpkgs.legacyPackages.x86_64-linux
# myAgda = pkgs.agda.withPackages (p: [ p.standard-library p.agda-categories ])
# agdaModePath = import ./get-agda-mode-path.nix { inherit myAgda pkgs; }
