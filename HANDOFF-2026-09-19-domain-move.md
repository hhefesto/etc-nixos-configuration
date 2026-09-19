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

## Inventory (survey of every checkout under ~/src, 2026-09-19)

Config-only, done on this branch: the six option values in `flake.nix`
(directo/xpsoasis/aaspectra `serverName`, xpsoasis `cookieDomain` and
`spectraUrl`, aaspectra `oasisUrl`), the ACME-guard unit names, the pure
checks, the refl block, the `xty.nix` pin, `Claude.md`. Every project module
derives ACME, forceSSL, public base URL, cookie domain and cross-links from
those options; directo's Mercado Pago `notification_url` and Google OAuth
`redirectUri` follow `DIRECTO_PUBLIC_BASE_URL`, its cookies are host-only.
Refl derives its WebSocket origin and cookie policy from `hostname`.

Personal site `~/src/hhefesto.com` (GitHub Pages): CNAME, canonical and
`og:url` moved to hhefesto.dev in local commit `9fd2dea` (**not pushed**);
apex `A` records to GitHub Pages (185.199.108-111.153, DNS-only) and
`www` CNAME → hhefesto.github.io created on the zone.

Code that still names an old domain (needs a code change + push, out of
this pass): `xpsoasis/static/js/checkVersion.js` (legacy Yesod asset whose
`len = 21` parses the URL by length); `xpsoasis` mail templates and
`Softwares.hs` link to `xpsoasis.org` (pre-existing, not .com);
`aanalyzer-classic` `headless-backend` Delphi client `PUnit2.dfm` posts to
`https://dev.hhefesto.com/api/recivePost` (compiled, distributed);
`hhefesto.github.io/contact.markdown` links hhefesto.com.

## Remaining / external (user)

- `git push` the three local commits when ready: consumer branch `refl-xty`
  (`b3564d6`, also still unmerged into master), `~/src/hhefesto.com` master
  (`9fd2dea`), and refl master docs (see `~/src/refl`). GitHub Pages: set
  the custom domain to hhefesto.dev in the repo settings after the push
  (the CNAME file alone is not enough) and enable "Enforce HTTPS" once the
  certificate is issued.
- Mercado Pago dashboard webhook `https://directo.hhefesto.com/api/webhooks/mercadopago`
  → `https://directo.hhefesto.dev/api/webhooks/mercadopago` (new
  preferences self-correct; the dashboard entry and in-flight ones do not).
- Google Cloud console: authorized redirect URIs
  `https://directo.hhefesto.dev/api/auth/<provider>/callback` and the
  JavaScript origin. Stripe dashboard: check for a webhook on the old host.
- Mail: SPF/DKIM/DMARC for hhefesto.dev if mail should come from it (xpsoasis
  sends through msmtp with the Gmail app password; sender domain lives there).
- Users: the xpsoasis `cookieDomain` change logs everyone out; web-push
  subscriptions are per origin and must be re-subscribed (do **not** rotate
  the VAPID keys at the same time).
- `chmod 600 ~/cloudflare-api-token`.

## Log

- 2026-09-19 11:4x: token verified read-only (zone list); four A records
  created on hhefesto.dev; consumer edits started.
- 2026-09-19 12:0x: consumer branch committed (`b3564d6`): xty closure
  `jwp2qrb7…-nixos-system-xty-26.11.20260831.34ab990` built, pure checks
  passed. Apex/www records created. Awaiting the user's go for
  `nix run .#deploy-xty`; after the switch start the four
  `acme-<name>.service` units by hand and verify, then drop the mkForce
  guards and redeploy.
- 2026-09-19 12:50: first `.dev` deploy succeeded cleanly (xty generation 70,
  `jwp2qrb7…`); docxty.net and xty-y-dan.net stayed 200 throughout; all four
  Let's Encrypt certificates were issued during the switch despite the
  mkForce guards (nginx pulls the acme units in); refl answers 200 with
  `__Host-refl; Secure`, port 3007 is closed; xpsoasis serves
  `spectraAppUrl = https://aaspectra.xpsoasis.hhefesto.dev`; directo redirects
  http → https. **Cloudflare's Universal SSL covers only one subdomain
  level**, so `aaspectra.xpsoasis.hhefesto.dev` failed the TLS handshake
  through the proxy and was switched to DNS-only (origin cert directly).
  `refl-browser-test` against https://refl.hhefesto.dev passed with all three
  provers. Second deploy (guards removed) started.
- 2026-09-19 13:0x: second deploy (guards removed) succeeded; final state
  in "Final state" below.

## Final state (2026-09-19)

- xty generation 71 serves https://directo.hhefesto.dev,
  https://xpsoasis.hhefesto.dev (Spectra link → aaspectra), 
  https://aaspectra.xpsoasis.hhefesto.dev (DNS-only record, origin cert) and
  https://refl.hhefesto.dev, plus the unchanged docxty.net and xty-y-dan.net.
  Certificates: Let's Encrypt, renewed by the acme timers.
- Local, unpushed commits: consumer branch `refl-xty` (still not merged into
  master; the "WIP before refl-xty" stash holds the cardano work),
  `~/src/hhefesto.com` master (`9fd2dea`), `~/src/refl` master docs.
- The apex hhefesto.dev points at GitHub Pages but serves nothing until
  `~/src/hhefesto.com` is pushed and the repo's custom domain is set.
