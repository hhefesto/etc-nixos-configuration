# CLAUDE.md — etc-nixos-configuration

## FP taste

Primary languages: **Nix, Haskell, Agda**. Strongly prefers functional, type-driven, declarative solutions. When explaining code, favour equational reasoning and type-driven thinking over imperative walkthroughs. Do not suggest Python/Bash alternatives without a clear reason (small Bash commands are OK) — reach for Nix derivations or Haskell programs first.

- Emacs (spacemacs) is the primary editor. Do not suggest switching editors or IDEs.
- Rebuild shorthand: `sn` → `sudo nixos-rebuild -v switch --flake ~/src/etc-nixos-configuration`.

---

## Repo layout

**Flat** — everything lives at the repo root; there are no `hosts/`, `modules/`, or `users/` subdirectories. Do not create subdirectory trees without explicit request.

| File | Purpose |
|---|---|
| `flake.nix` | Entry point. Uses `flake-parts`. `mkHost` helper. Builds `nixosConfigurations.{olimpo,delfos,xty}`, `deploy.nodes.xty`, pre-deploy checks, `apps.deploy-xty`. |
| `configuration-core.nix` | Every host: users (agenix-managed login hash in `secrets/user-password.age`), ssh, nix settings, agenix module import. |
| `configuration-workstation.nix` | Workstations: dev tools, zsh (system-wide aliases; root shell is zsh), docker, claude-code/opencode overlays. |
| `configuration-gui.nix` | Workstations: X11/xmonad, desktop apps, fonts, pipewire, LAN firewall. |
| `configuration.nix` | 7-line stub = core + workstation (imported by olimpo/delfos only). |
| `home.nix` | home-manager for `hhefesto` (NixOS module, `useGlobalPkgs` + `useUserPackages`). |
| `olimpo.nix` / `delfos.nix` / `xty.nix` + `hardware-configuration-*.nix` | Per-host. olimpo↔delfos share LAN ssh-ng binary caches; delfos has dynamic timezone; xty is the headless production server (62.238.6.4, fail2ban, keys-only SSH). |
| `secrets/` | agenix: `secrets.nix` recipients + `user-password.age` (rotate: `secrets/rotate-user-password.sh`). |
| `xmonad.hs`, `xmobarrc-olimpo`, `xmobarrc-delfos` | xmonad config; `@xmonadShortenLength@` substituted per host. |
| `spacemacs/`, `doom.d/` | Emacs configs. |

**Navigation:** `flake.nix` → `mkHost` → per-host module lists (workstations: `configuration.nix` + gui + projects desktop-profile; xty: core + projects production-profile).

### Hosts & hosted projects

- **olimpo**, **delfos** — workstations; test the app stacks with desktop profiles.
- **xty** — production. Hosts (all sharing one postgres 16 on 5432):

| Input | App | Prod domain | Backend port | DB |
|---|---|---|---|---|
| `docxty` | expedientes (medical records) | docxty.net | 3000 | `expedientes` |
| `wedding-page` | wedding RSVP | xty-y-dan.net | 3001 | `wedding` |
| `directo` | store (refacciones, Querétaro) | directo.hhefesto.com | 3002 | `directo` |
| `xpsoasis` | AAnalyzer (Yesod) | xpsoasis.hhefesto.com | 3003 | `aanalyzer_yesod` (user `analyzer`) |

Workstation dev nginx ports: expedientes 80, wedding 8084, directo 8085, xpsoasis 8086.

Deploy: `nix run .#deploy-xty` (docxty backup health check → pure checks → live SSH checks → build → deploy-rs). Backup health check standalone: `nix run .#check-docxty-backups` (`DOCXTY_BACKUP_CHECK_FAST=1` skips the restic integrity pass). **Update policy: manual only** — no `system.autoUpgrade`; every prod update goes through the check pipeline.

### Key flake inputs

`nixpkgs` (nixos-unstable), `flake-parts`, `deploy-rs`, `home-manager` (release-25.11), `agenix`, `docxty`/`wedding-page`/`directo`/`xpsoasis` (project repos, git+ssh/github; xpsoasis lives at `rdataa/xpsOasis?ref=xpsoasis`), `claude-code-nix`, `opencode`, `telomare`, `spacemacs` (non-flake).

Binary caches: `hercules-ci.cachix.org`, `telomare.cachix.org`, `nixcache.reflex-frp.org`, `claude-code.cachix.org`.

`nixpkgs.config.allowUnfree = true`.

### Conventions

- **Per-host parametrisation** via `extraSpecialArgs` (e.g., `xmonadShortenLength`), not conditionals inside shared files.
- **Project modules own project code**; this repo only sets collide-able facts (ports, db names, serverName, profile) and host concerns.
- **Secrets**: agenix only. App secrets live in each project repo (`${input}/secrets/*.age`); this repo's `secrets/` has the login hash. Never commit plaintext credentials or password hashes.
- **Test project changes without pushing**: `nix build .#nixosConfigurations.olimpo.config.system.build.toplevel --override-input docxty path:$HOME/src/expedientes -L` (new files in the project must be `git add`ed — flake purity).
- **Build after changes**: `nix build .#nixosConfigurations.olimpo.config.system.build.toplevel -L`.

---

## xmonad setup

xmonad is configured as a **NixOS module** (`configuration-gui.nix:98-108`), not via home-manager. Maybe we should change to home-manager for a better xmonad experience (reload of xmonad still needs logout from the xsession when it should only need `M-q`)

```
services.xserver.windowManager.xmonad = {
  enable = true;
  enableConfiguredRecompile = true;
  config = builtins.replaceStrings ["@xmonadShortenLength@"] ["${toString xmonadShortenLength}"] (pkgs.lib.readFile ./xmonad.hs);
  enableContribAndExtras = true;
  extraPackages = haskellPackages: [ ... ];
};
```

Launched via **GDM** (`services.displayManager.gdm.enable = true`, `defaultSession = "none+xmonad"` at `configuration-gui.nix:110-111`).

`sessionCommands` (`configuration-gui.nix:112-127`) swaps Caps_Lock ↔ Control_R (via xmodmap), runs `dbus-update-activation-environment --systemd --all`, and tees xsession output to `~/.xsession.log`.

**Startup hook** (`xmonad.hs:15-23`): nautilus, brave, feh wallpaper, gnome-terminal, emacs, signal-desktop, gnome-control-center. No `spawnOnce "dunst"` — dunst is a systemd user unit.

**Notification daemon:** `dunst` + `libnotify` installed as system packages (`configuration-gui.nix:22-23`). `home.nix:100` has `services.dunst.enable = true` so dunst runs as a proper systemd user service with correct dbus activation.

### The `<Print>` key / screenshot notification problem

**Status:** open as of 2026-04-20. Prior dbus/dunst hypothesis resolved — both fixes are already applied (`services.dunst.enable = true` in `home.nix:100`; `dbus-update-activation-environment` in `configuration-gui.nix:124`; dunst verified `active (running)`). `notify-send test` from a terminal works.

**Notification daemon:** dunst is running (verified Apr 20 2026). `notify-send test` from a terminal works.

**Current status (Apr 20 2026):** `sn` was run, xmonad binary rebuilt at 12:15, xsession started at 12:21 (new binary active). After pressing `<Print>`, `/tmp/xmonad-print.log` still does not exist. The diagnostic binding at `xmonad.hs:60` writes the log *before* notify-send — so the spawn itself is never running. This is a **keybinding-not-firing** problem, not a notify-send problem.

**Next debug steps (run in xmonad session, in order):**

1. Check what keysym `<Print>` actually produces — it may be `XF86Print`, `Sys_Req`, or nothing:
   ```sh
   xev -event keyboard   # press Print; look for keysym line
   ```
   If not `keysym 0xff61, Print` → fix the binding in `xmonad.hs:60-61` to match actual keysym.

2. Confirm `additionalKeysP` list is live by testing another binding:
   ```sh
   # Press M-j (xmonad.hs:66) — should trigger amixer + notify-send Volume
   ```

3. Simulate Print programmatically to rule out physical-key grab:
   ```sh
   xdotool key --clearmodifiers Print
   ls /tmp/xmonad-print.log
   ```

4. Check xmonad stderr for parse errors:
   ```sh
   grep -iE "error|warn" ~/.xsession-errors | tail -40
   ```

**Branch A — wrong keysym from xev:** Update `xmonad.hs:60-61` from `<Print>` to the real keysym (e.g., `<XF86Print>`), then `sn` + `M-q`.

**Branch B — `M-j` also broken:** `additionalKeysP` is broken. Check GHC recompile log in `~/.cache/xmonad/build-x86_64-linux/`.

**Branch C — `xdotool key Print` creates the log but physical Press does not:** a hardware/xkb remapping issue; add explicit xmodmap in `configuration-gui.nix:112` sessionCommands.

**If spawn fires but notify-send fails (log exists, notify≠0):** check DBUS_SESSION_BUS_ADDRESS in the log. If missing → `dbus-update-activation-environment` doesn't propagate to xmonad `spawn` children; fix with `systemd-run --user --scope notify-send …` in the binding.
