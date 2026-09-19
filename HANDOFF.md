# Handoff: hhefesto.com → hhefesto.dev — started 2026-09-19

Fresh handoff for the domain move. Older history (the July hardening, the
Refl rollout of 2026-09-18 and its nginx outage) is in
`HANDOFF-2026-09-18-refl-rollout-and-earlier.md`; the Refl game's own log is
`~/src/refl/HANDOFF-ROLLOUT.md`.

## Mission (user's words, condensed)

hhefesto.com is dead (no nameservers). The user bought **hhefesto.dev**.
Move every hhefesto.com thing to hhefesto.dev; Refl lives at
**refl.hhefesto.dev**. The Cloudflare API token is `~/cloudflare-api-token`
(**secret**: never print, log, or commit it; it should be mode 600, it was
644). **Do not push to any git remote.** Any xty change goes through
`nix run .#deploy-xty` and needs the user's explicit go.

## Facts established

- Cloudflare account holds the zones docxty.net, xty-y-dan.net, cfo-vision.com
  and hhefesto.dev (zone id `b641959f…`, created 2026-09-19, active,
  nameservers alexandra/reese.ns.cloudflare.com). Convention on the live
  zones: one `A` → 62.238.6.4, **proxied**, SSL mode **full**,
  `always_use_https` off (ACME HTTP-01 passes through the proxy on port 80).
  `.dev` is on the browser HSTS preload list: everything must be https.
- The four names were created 2026-09-19 with the same shape (proxied A →
  62.238.6.4): `refl`, `directo`, `xpsoasis`, `aaspectra.xpsoasis`
  under hhefesto.dev. Public resolution returns Cloudflare edge IPs.
- Where hhefesto.com lived (consumer repo, branch `refl-xty`):
  `flake.nix` xty profile blocks (directo `serverName`, xpsoasis
  `serverName`/`cookieDomain`/`spectraUrl`, aaspectra `serverName`/`oasisUrl`,
  the `acme-aaspectra…` mkForce that keeps that ACME order out of activation),
  the pure pre-deploy vhost/ssl443 checks, the refl block (plain http on
  62.238.6.4:3007 because there was no DNS), `xty.nix`'s `networking.hosts`
  pin of the .com names (added 2026-09-18 because nginx refuses to start
  when a `proxy_pass` upstream does not resolve), `Claude.md`'s host table.
  A survey of the project repos for hard-coded domains is in progress; code
  changes there cannot reach xty without a push, so this pass is config-only
  and anything found in code is listed under "Remaining".

## Plan

1. Consumer config (branch `refl-xty`, then merge to master later):
   all `serverName`s, `cookieDomain`, `oasisUrl`, `spectraUrl` → `.dev`;
   refl: `hostname = "refl.hhefesto.dev"`, `ingress.enable = true`, no
   `openFirewall` (port 3007 closes; origin becomes https); keep the
   ACME-out-of-activation mkForce for **every new vhost** until each cert
   exists (aaspectra, directo, xpsoasis, refl) so a failed order cannot fail
   the switch; pure checks renamed to `.dev`, drop the "refl ingress must
   stay off" check, add `refl.hhefesto.dev` vhost + ssl443;
   `xty.nix` pin → the `.dev` names (nginx upstream resilience, and the
   aaspectra → xpsoasis auth subrequest then goes to the origin instead of
   round-tripping through Cloudflare).
2. Refl repo: README/CLAUDE/HANDOFF-ROLLOUT/memory mentions → `.dev`
   (no code: the module already takes `hostname`).
3. Build xty, pure check, live check, then **ask the user** and
   `nix run .#deploy-xty`. After the switch: start the four ACME orders
   (`systemctl start acme-<name>.service`), check `https://<name>/` through
   Cloudflare, refl's WebSocket over the proxy, cookies, then remove the
   mkForce lines and redeploy so renewals are wired normally.
4. Old certs/vhosts for `.com` disappear with the switch; nothing to clean.

## Remaining / external (user)

- Mercado Pago webhook is registered at
  `https://directo.hhefesto.com/api/webhooks/mercadopago` → re-register at
  the `.dev` URL (the backend also polls MP as a fallback).
- Google OAuth redirect URIs for directo, if used → `.dev`.
- Any hard-coded `hhefesto.com` in the project repos (survey pending).
- `chmod 600 ~/cloudflare-api-token`.

## Log

- 2026-09-19 11:4x: token verified read-only (zone list); four A records
  created on hhefesto.dev; consumer edits started.
