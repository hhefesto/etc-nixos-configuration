# Refl tutorial review and Olimpo module rollout — 2026-09-19

Previous domain-move history: `HANDOFF-2026-09-19-domain-move.md`.
Earlier rollout/outage: `HANDOFF-2026-09-18-refl-rollout-and-earlier.md`.
Full teaching/review evidence: `~/src/refl/HANDOFF.md`.

## Review baseline and findings

Consumer `05765c2`, refl `13f600c`; both checkouts are on **master**, initially
clean. The old `refl-xty` branch/unmerged descriptions are historical.
Production uses https://refl.hhefesto.dev with nginx/ACME, not public :3007.

**High, open:** `deployXty` has backup/pure/live gates, but no candidate versus
running-system gate against unrelated restarts/reloads. Block production until
one establishes that shared nginx, PostgreSQL, networking, docxty and all other
projects remain untouched. Keep backup checks and disabled automatic rollback.

**Medium:** refl's timed draft flush needs immediate-navigation browser coverage;
new tests exercise same-task input/navigation, exact Unicode restoration and
per-language drafts. See refl handoff for final results.

**Low, addressed:** stale branch, publication, hint and deployment documentation.

**Unverified:** KVM NixOS module test; Olimpo has no `/dev/kvm`. Isolated prover
and local module acceptance do not substitute for VM resource-exhaustion tests.

## Local rollout and approval

Pin only the reviewed refl snapshot; do not update unrelated dependencies.
Add `ns = "nixos-rebuild switch --sudo --flake ~/src/etc-nixos-configuration"`
to workstation zsh aliases. Existing `sn` remains available. The user's final
path spelling had an extra slash; use the actual existing checkout above.

Build with `nixos-rebuild build --flake ~/src/etc-nixos-configuration`.
The user then runs `nixos-rebuild switch --sudo --flake
~/src/etc-nixos-configuration`; start a new zsh afterwards for `ns`.
After switch, verify http://127.0.0.1:3007 through the module and let the user
assess the lesson. Explicit production approval is still required.

Exact reviewed source, consumer change, build result and test results pending.
No production switch, publication, remote push or local activation performed.

## Production and rollback

Historical production: xty generation 71 at the previous pinned refl revision;
not re-deployed by this review. Before approved deployment, record the actual
running system and previous refl ExecStart/input, retain the old closure with
a GC root and back up refl state. Compare candidate services/activation effects
with the running system; block unrelated restart/reload changes. Monitor public
site availability and protected service PIDs throughout activation.

For refl-only rollback, repin the previous refl input on the current consumer,
build and pass the same unrelated-service gate before activation. Never use a
whole-system `--rollback` for a refl regression. Keep player state unless a
specific incompatible format change requires restoring its backup.

## Verified candidate

Reviewed implementation: refl `476f27d3d9bb7ebbc3a1ba3a65a2083bfe9223e7`.
Immutable source `/nix/store/y3vyjacprm8dpkagr5fiy98b10anl36a-source`, NAR hash
`sha256-QzAOP7R3u1meVRKGOB2xToCq9TAcTW/jVDUI9qXvrv0=`. Retained by
`~/src/refl/result-reviewed-source`. The lock override is persistent: the normal
build/switch commands select it without flags. Exactly one lock node changed:
`refl`; all unrelated pins remain identical. Previous refl pin:
`f529203020105b3e995833798348307ab80868a4`. Nothing pushed.

Passed in refl: 67 native tests; manifest and website builds; 122 content checks
including host Lean; full `nix flake check` (106 in-sandbox content checks,
browser with explicit Lean session skip, smoke/security/Bend); `verify-local`
with 122 isolated checks, all-three-prover Chromium flows, failure/retry and
security. Browser checks both actual authored hint proofs against level
restrictions, rejects wrong proofs and leaves templates unfinished, checks hint
order/building blocks before completion, selectors and exact immediate drafts.

The immediate edit/navigation test reproduced a lost edit. Fixed by reading the
live textarea on departure rather than stale reactive text, and prioritizing the
flush over simultaneous debounce. Repeated Unicode navigation and all language
drafts now pass. Close/unmount delays remain; no claim of crash/tab-close or
arbitrary-network-stall durability. KVM module test still unverified.

The running module at http://127.0.0.1:3007 and public production health both
reported 61 variants before activation. These probes do not validate the new
candidate. After the user's switch, run the updated browser suite in existing
service mode against :3007 and verify its ExecStart references the new closure.
Olimpo lesson assessment and explicit xty approval are pending.
