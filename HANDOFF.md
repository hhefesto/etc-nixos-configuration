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

### DONE (Phase 0 — this branch, builds green for olimpo AND xty)

- Vesiet: input, factory, xty wiring, all 6 pre-deploy-check references removed; lock pruned.
- fail2ban on xty (`xty.nix`), firewall trim (`configuration-gui.nix`).
- H2 interim: 0400 + `LoadCredential admin-hash:` + env override to
  `/run/credentials/wedding-backend.service/admin-hash` (consumer flake, wedding production block).
- `determinate` input removed; Claude.md stale sections rewritten (kept FP-taste,
  conventions, open xmonad Print-key debugging section); README useful.
- H1 wiring: `configuration-core.nix` imports agenix globally; root+hhefesto use
  `hashedPasswordFile = config.age.secrets.user-password.path` **gated on
  `builtins.pathExists ./secrets/user-password.age`** with the old (burned) hash
  as fallback so builds stay green until rotation. `secrets/secrets.nix` has
  recipients: admin key (`~/.ssh/hetzner_ed25519.pub` = hhefesto@rdataa.com),
  olimpo/delfos/xty host keys.

### Immediate next steps (in order)

1. **User runs `bash secrets/rotate-user-password.sh`** (interactive; prompts
   for NEW password — old one is burned in git history). Then
   `git add secrets/user-password.age`, delete the `burnedHash` fallback branch
   in `configuration-core.nix`, rebuild, and verify `sudo` accepts the new
   password in an open session before logging out.
2. **Phase 2 — wedding-website** (`~/src/wedding-website`): rewrite
   `nixosModules/wedding.nix` (positional factory) → `services.wedding.profile`
   options module; split vhost out of `frontend.nix` into `nginx.nix`;
   self-default packages (`wedding-backend`, `website`, `admin-website`);
   move agenix decls in from consumer; LoadCredential permanent here;
   hardening + HSTS + limit_req. Consumer keeps its old factory until Phase 5.
3. **Phase 3 — expedientes** (`~/src/expedientes`, input name `docxty`): same,
   PLUS move TLS/ACME into the module (consumer currently does it manually) and
   fix `database.nix` password hook from `postgresql.postStart` →
   `postgresql-setup.service.postStart` (kills consumer's inline mkForce hack).
   Keep seed (`startingBackup`) + restic backup modules, wire through profile.
   Medical data — extra care, no on-disk path changes.
4. **Phase 4 — cfo** (`~/src/cfo-as-a-service`): smallest diff. 2-mode enum,
   self-default packages, in-module agenix, move the desktop
   `cfo-local-password` writeText from consumer into the module's dev mode.
5. **Phase 5 — consumer rewrite** to the end-state above; update
   `preDeployXty` option-path references; push all project repos,
   `nix flake update docxty cfo-as-a-service wedding-page`; build all hosts +
   `nix flake check`.
6. **Expedientes backup (BLOCKS deploy)**: check `services.expedientes.backup`
   actually enabled/running on xty (`ssh root@62.238.6.4 systemctl status …`);
   if not: manual `pg_dump` of expedientes + rsync of /var/lib/expedientes/html
   off-host, verify with `pg_restore --list`.
7. **Phase 6 — deploy**: `nix run .#deploy-xty` — ONLY after #6 AND explicit
   user confirmation. Verify: HTTPS+HSTS on 3 domains, rate limit trips (429),
   0400 secrets, nmap shows only 22/80/443.

### Gotchas discovered (will bite you if forgotten)

1. **Flake purity**: new files in any project repo must be `git add`ed before
   `nix build` sees them.
2. **Dev loop**: test project changes against olimpo with
   `nix build .#nixosConfigurations.olimpo.config.system.build.toplevel --override-input docxty path:$HOME/src/expedientes -L`
   (inputs: `docxty`, `cfo-as-a-service`, `wedding-page`).
3. **Inline postgres module in consumer flake (xty host)**: blanks
   `postgresql.postStart` with mkForce and re-adds the expedientes `ALTER USER`
   in `postgresql-setup.postStart` — exists ONLY because expedientes'
   `database.nix` hooks the wrong unit. Fix in Phase 3, then delete it. The
   `postgresql_16` pin inside it must survive (move to `xty.nix`).
4. **agenix identityPaths**: the expedientes desktop branch sets
   `age.identityPaths = [ "/home/hhefesto/.ssh/hetzner_ed25519" ]` on
   workstations — overrides host-key identities. `user-password.age` is
   encrypted to admin + all three host keys, so it decrypts either way. Keep
   both mechanisms in mind when moving agenix decls into project modules.
5. **LoadCredential path**: systemd credentials land at
   `/run/credentials/<unit>.service/<name>`; `Environment=` does NOT expand
   `%d`, hence the hardcoded path in the consumer's wedding block.
6. **Pre-deploy checks** (`flake.nix`, perSystem): assert postgres major=16,
   ensure DBs/users, unit ordering, vhosts+443, `/run/agenix/*` paths. They
   pin today's names — update alongside Phase 5, never delete.
7. **wedding `frontend.nix` IS the nginx module** (same for old vesiet);
   cfo/expedientes have separate `nginx.nix`. Normalize to separate `nginx.nix`.
8. **configuration-gui.nix** carries an unrelated pre-existing change
   (`enableConfiguredRecompile = false`) from the user's xmonad work — keep it.

### Task list snapshot (recreate on delfos)

1. ~~Phase 0 consumer quick wins~~ DONE
2. User runs rotate-user-password.sh → then remove fallback (pending)
3. Phase 2 wedding normalization (pending)
4. Phase 3 expedientes normalization (pending)
5. Phase 4 cfo alignment (pending)
6. Phase 5 consumer flake rewrite (pending)
7. Expedientes backup verification — BLOCKS deploy (pending)
8. Phase 6 deploy xty — needs backup done + EXPLICIT user confirmation (pending)

### Reference: audit evidence pointers

- H1: `configuration-core.nix` (fallback hash still visible in the let-binding, by design until rotation)
- H2 interim: consumer `flake.nix` wedding production block (search `LoadCredential`)
- fail2ban: `xty.nix`; firewall: `configuration-gui.nix`
- Project module option surfaces + asymmetry table: re-derive quickly by reading
  `~/src/<repo>/nixosModules/*.nix`; the key asymmetries are listed in the
  gotchas above.
