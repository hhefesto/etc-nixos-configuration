#!/usr/bin/env sh

cd ~/src/etc-nixos-configuration
nix build .#darwinConfigurations.ECM037LMBP-1.system
./result/sw/bin/darwin-rebuild switch --flake .
