# The transcript renderer. Kept as a standalone expression so both the NixOS
# module and the flake's `packages` output build the same derivation from the
# one Haskell source at the repo root (same idiom as xmonad.hs).
{ pkgs }:

pkgs.writers.writeHaskellBin "llm-transcript"
  { libraries = hp: [ hp.aeson hp.base64-bytestring hp.regex-tdfa ]; }
  ./llm-transcript.hs
