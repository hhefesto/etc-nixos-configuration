#!/usr/bin/env bash
# Rotate the shared root/hhefesto login password.
# Prompts for the new password (never echoed, never stored in plaintext),
# hashes it with SHA-512 crypt, and age-encrypts the hash for all hosts.
set -euo pipefail
cd "$(dirname "$0")"

recipients=(
  "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBAolzCtF1t8rPKSRzvREQPBUjxRAi5medog8Ebi0n/G hhefesto@rdataa.com"
  "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIP5EUe2fiscGEdLFXkTfxPLRmHuRBwqCbHcFSabqVWN1 root@olimpo"
  "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIINM3/adCok24i8fl600FBto4A/thxXaKpDu5B3ec3QT root@delfos"
  "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJ5cWilmgGZa24PrEFftyajabwxHvR4jxvkIvqkyCtmG root@xty"
)

args=()
for r in "${recipients[@]}"; do
  args+=(-r "$r")
done

hash=$(nix run nixpkgs#mkpasswd -- -m sha-512)
printf '%s' "$hash" | nix run nixpkgs#age -- "${args[@]}" -o user-password.age
echo "wrote $(pwd)/user-password.age"
echo "now: git add secrets/user-password.age && rebuild"
