# Session handoff: environment review, xty hardening, module normalization

Written 2026-07-04 on olimpo, for continuing on delfos. Everything a fresh
session needs is in this file. The work spans this repo **and** the project
repos under `~/src` (`wedding-website`, `expedientes`, `cfo-as-a-service`).

## Mission (user's words, condensed)

1. **Security review** of the whole environment — "is the xty server safe from hackers?"
2. **Make this repo much leaner**: each project repo exports **one** NixOS
   module consumed here with a **single import**; only collide-able facts stay
   explicit in this repo (ports, database name — each app has its own DB on the
   shared postgres — serverName, profile). Move ALL project-dependent code into
   the project repos.
3. **Vesiet is removed entirely** (user decision mid-session). Its DB still
   exists on xty; drop manually if desired after next deploy.
4. **HARD GATES**: (a) expedientes data must be verifiably backed up BEFORE any
   xty deployment; (b) deployment itself needs explicit user confirmation.

Hosts: **xty** = production (62.238.6.4, headless, deploy-rs as root),
**olimpo**/**delfos** = workstations that test the same app stacks with
desktop profiles.

## Security audit findings (2026-07-03)

Verified-good posture: SSH keys-only + prohibit-password root; postgres not
exposed (localhost, firewall only 22/80/443); ACME/forceSSL on all prod vhosts;
agenix for prod secrets; DynamicUser backends; trust-auth gated to desktop
profiles only.

| # | Sev | Finding | Status |
|---|---|---|---|
| H1 | HIGH | Real SHA-512 crypt hash committed in `configuration-core.nix`, reused for root+hhefesto on all hosts; passwordless wheel sudo on xty | **Wired, rotation pending** (see "Immediate next steps") |
| H2 | HIGH | `wedding-admin-password-hash` deployed 0444 (world-readable) | **FIXED** (0400 + systemd LoadCredential; interim fix lives in consumer flake, permanent home is the wedding repo in Phase 2) |
| M1 | MED | No rate limiting on login endpoints (expedientes = medical records!), no fail2ban | fail2ban on xty **DONE**; nginx `limit_req` pending, goes into each project's vhost during normalization |
| M2 | MED | No auto security updates | **Decided: manual-only policy**, documented in Claude.md — deploys go through the check pipeline |
| M3 | MED | wedding/expedientes backends lack systemd hardening (cfo has a full block) | Pending — copy cfo's hardening block during normalization |
| L1 | LOW | No HSTS/security headers on any vhost | Pending — add during normalization |
| L2 | LOW | Workstations opened 3000/5432 to LAN | **FIXED** (`configuration-gui.nix` firewall trim) |

## Approved design (plan file content, survives only here)

### Canonical module interface — all projects converge on cfo's shape

Typed options module `services.<name>.profile.*` (NOT a positional factory).
Each project's `flake.nix` exports `nixosModules.default` **closing over its
own `self`** so packages and secret paths default correctly.

```nix
services.<name>.profile = {
  enable;                                  # mkEnableOption
  mode;                                    # enum [ "development" "production" ]
  serverName;                              # str — vhost/domain
  ports = { nginx; backend; database ? 5432; };   # collide-able → consumer sets
  database = { name ? "<name>"; user ? name; };   # collide-able
  acmeEmail ? "hhefesto@rdataa.com";
  openFirewall ? true;
};
```

Derived INSIDE the module: packages default to `self.packages.${pkgs.system}.*`;
`mode == "production"` declares its own `age.secrets` (files at
`${self}/secrets/*.age`, mode 0400) + forceSSL/ACME/443 + cookieSecure;
`mode == "development"` gives postgres trust auth for its own user,
networking.hosts alias, dev conveniences. Vhost gains HSTS + security headers +
`limit_req` on auth endpoints (M1/L1); backends gain cfo's hardening block (M3).

Naming: `serverName` everywhere; per-project extras stay as options
(wedding: videoDir/videoMaxBytes/admin hash; expedientes: htmlDir,
startingBackup seed, backup.* restic; cfo: backup.* toggle). cfo's unused
`staging` mode collapses to the 2-mode enum.

### Consumer end-state (this repo's flake.nix)

Per host: import `inputs.<x>.nixosModules.default` once + a settings block:

```nix
services.expedientes.profile = { enable = true; mode = "production";
  serverName = "docxty.net";     ports = { nginx = 80; backend = 3000; }; };
services.cfo.profile         = { enable = true; mode = "production";
  serverName = "cfo-vision.com"; ports = { nginx = 80; backend = 3033; frontend = 8083; }; };
services.wedding.profile     = { enable = true; mode = "production";
  serverName = "xty-y-dan.net";  ports = { nginx = 80; backend = 3001; }; };
```

Workstations: `mode = "development"`, cfo nginx 8082 / wedding 8084,
serverName `*.local`. Dies from consumer: the remaining factory functions,
manual agenix blocks, expedientes' manual TLS block, desktop trust-auth lines,
package threading, and the inline xty postgres-compat module (see gotcha #3).

### Invariants — MUST NOT change (prod data)

DB names/users (`expedientes`, `cfo`, `wedding`), postgres **16** on 5432
(pin stays in consumer as host concern), `/var/lib/expedientes*`,
`/var/lib/wedding/videos`, `/run/agenix/<existing-names>`, systemd unit names,
domains. Only option paths and code location change.

## State of play

### DONE (as of 2026-07-04, on delfos)

- Phase 0 (see git history): vesiet removal, fail2ban, firewall trim, H2
  interim fix, H1 wiring (rotation still pending).
- **Phase 2 — wedding** (`04331bc` on master, pushed): services.wedding.profile
  module, nginx.nix vhost split (HSTS/headers/limit_req on /api/admin/login),
  in-module agenix, permanent LoadCredential, hardening. Legacy factory kept.
- **Phase 3 — expedientes** (`b049584`, pushed): same treatment; database.nix
  password hook fixed to postgresql-setup.service; TLS/ACME in-module
  (mkDefault so legacy overrides win); limit_req on /api/login; restic backup
  enabled by default in production mode; seed ordered after postgresql-setup.
- **Phase 4 — cfo** (`1a45928`, pushed): profile.nix wrapper (self-defaults,
  in-module agenix, dev writeText password moved in); staging enum collapsed.
- **Phase 5 — consumer** (`1b6cf2d` on env-review-hardening): factories/manual
  agenix/inline postgres hack deleted; postgresql_16 pin → xty.nix; per-host
  single-import + profile blocks; pre-deploy checks updated (LoadCredential
  path; postStart just needs no ALTER USER). All hosts build; flake check and
  pre-deploy-xty pass.
- **Backup verified (deploy gate #1 SATISFIED)**: the restic mechanism had
  been dead since Apr 25 (module was only in expedientes' old self-deploy).
  Manual restic snapshot `53235259` taken 2026-07-04 from xty (fresh pg_dump +
  html); full repo mirrored to delfos at ~/.local/share/expedientes/restic-mirror;
  restic check clean; dump verified with pg_restore --list. Post-deploy the
  daily 03:00 timer returns permanently.

### Remaining

1. **User runs `bash secrets/rotate-user-password.sh`** (interactive; old hash
   burned in git history) → git add secrets/user-password.age, remove the
   burnedHash fallback in configuration-core.nix, rebuild, verify sudo.
2. **Phase 6 — deploy**: `nix run .#deploy-xty` — needs explicit user
   confirmation (gate #2). Verify after: HTTPS+HSTS on 3 domains, 429 on
   login brute force, 0400 secrets, nmap 22/80/443 only, expedientes-backup
   timer active, drop stale vesiet DB + /run/agenix/vesiet-* if desired.

### Gotchas that still apply

- Flake purity: git add new files in project repos before nix build.
- Dev loop: --override-input docxty/cfo-as-a-service/wedding-page path:$HOME/src/<repo>.
- agenix identityPaths on workstations lives in the consumer's
  workstationServices block (admin key decrypts shared dev secrets).
- configuration-gui.nix carries the unrelated enableConfiguredRecompile=false
  (xmonad work) — keep.
- Project repos may move ahead on origin (happened twice); fetch/rebase before
  committing in them.
