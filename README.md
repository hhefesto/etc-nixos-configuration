# etc-nixos-configuration

NixOS flake for hhefesto's machines: `olimpo` + `delfos` (workstations) and `xty` (production server at 62.238.6.4 hosting docxty.net, cfo-vision.com, and xty-y-dan.net).

- Rebuild locally: `sn` (alias for `sudo nixos-rebuild switch --flake ~/src/etc-nixos-configuration`)
- Deploy production: `nix run .#deploy-xty`
- Details: `Claude.md`
