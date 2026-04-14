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
| `flake.nix` | Entry point. Uses `flake-parts`. Defines `mkHost` helper. Builds `nixosConfigurations.{olimpo,delfos}`. |
| `configuration.nix` | Shared system config (~410 lines): packages, services, X11/xmonad, zsh, pipewire, users. |
| `home.nix` | home-manager config for `hhefesto`. Integrated as a NixOS module (`useGlobalPkgs` + `useUserPackages`). |
| `olimpo.nix` + `hardware-configuration-olimpo.nix` | olimpo host. Imports `expedientes-local.nix`. |
| `delfos.nix` + `hardware-configuration-delfos.nix` | delfos host. Minimal. |
| `xmonad.hs` | xmonad Haskell config. `@xmonadShortenLength@` is template-substituted per host via `builtins.replaceStrings` in `configuration.nix:257`. |
| `xmobarrc-olimpo`, `xmobarrc-delfos` | Per-host xmobar configs. |
| `spacemacs/`, `doom.d/` | Emacs configs; copied into `~/.emacs.d` via home-manager activation script. |

**Navigation:** `flake.nix` → `mkHost` → `configuration.nix` (shared) + `{olimpo,delfos}.nix` (per-host).

### Key flake inputs

`nixpkgs` (FlakeHub), `determinate`, `flake-parts`, `home-manager` (release-25.11), `agenix`, `spacemacs` (non-flake git), `claude-code-nix`, `opencode`, `expedientes` (local at `/home/hhefesto/src/expedientes`).

Binary caches: `telomare.cachix.org`, `nixcache.reflex-frp.org`, `cache.iog.io`, `claude-code.cachix.org`.

`nixpkgs.config.allowUnfree = true`.

### Conventions

- **Per-host parametrisation** is done via `extraSpecialArgs` (e.g., `xmonadShortenLength`), not conditionals inside shared files.
- **Local flake inputs** for sibling in-progress projects (e.g., `expedientes` → `/home/hhefesto/src/expedientes`).
- **Template substitution** over multiple config files when the host delta is small.
- **Build after changes**: always try to build after making changes. Default command: `nix -Lv build .#olimpo`.

---

## xmonad setup

xmonad is configured as a **NixOS module** (`configuration.nix:254-264`), not via home-manager. Maybe we should change to home-manager for a better xmonad experience (reload of xmonad still needs logout from the xsession when it should only need `M-q`)

```
services.xserver.windowManager.xmonad = {
  enable = true;
  enableConfiguredRecompile = true;
  config = builtins.replaceStrings ["@xmonadShortenLength@"] ["${toString xmonadShortenLength}"] (pkgs.lib.readFile ./xmonad.hs);
  enableContribAndExtras = true;
  extraPackages = haskellPackages: [ ... ];
};
```

Launched via **GDM** (`services.displayManager.gdm.enable = true`, `defaultSession = "none+xmonad"` at `configuration.nix:265-266`).

`sessionCommands` (`configuration.nix:267-281`) swaps Caps_Lock ↔ Control_R (via xmodmap) and tees xsession output to `~/.xsession.log`.

**Startup hook** (`xmonad.hs:15-24`): `spawnOnce "dunst"`, nautilus, brave, feh wallpaper, gnome-terminal, emacs, signal-desktop, gnome-control-center.

**Notification daemon:** `dunst` + `libnotify` are installed as system packages (`configuration.nix:61-62`). There is no `services.dunst` NixOS module config and no `dunstrc` in the repo — dunst runs with defaults, spawned from `xmonad.hs:17`.

### The `notify-send` screenshot problem

**Status:** open as of commit `6be85f9` ("send-notify from xmonad still doesn't work").

Relevant keybindings in `xmonad.hs:61-68`:
```haskell
("<Print>",   spawn "scrot -e 'mv $f ~/Pictures/Screenshots && notify-send Screenshot $f'")
("M-<Print>", spawn "scrot -s -e 'mv $f ~/Pictures/Screenshots' || notify-send 'scrot failed'")
("M-j", spawn "amixer -q sset Master 2%- && notify-send Volume \"$(amixer get Master | grep -o '[0-9]*%' | head -1)\"")
("M-k", spawn "amixer -q sset Master 2%+ && notify-send Volume \"$(amixer get Master | grep -o '[0-9]*%' | head -1)\"")
```

**Likely root cause:** GDM starts the xmonad session but `DBUS_SESSION_BUS_ADDRESS` / dbus activation is not wired through reliably. `spawnOnce "dunst"` in the startup hook races against the session bus being ready, or inherits the wrong environment. `notify-send` silently no-ops (or exits 1) when it can't reach the session bus. The `scrot -e` subshell runs via `/bin/sh -c` which on NixOS does not carry `XDG_RUNTIME_DIR` / dbus env vars reliably.

**Candidate fixes (in preference order):**

1. **(Recommended) Let systemd --user manage dunst** via home-manager:
   ```nix
   # home.nix
   services.dunst.enable = true;
   ```
   Remove `spawnOnce "dunst"` from `xmonad.hs`. Home-manager generates a systemd user unit with correct dbus activation rules so `notify-send` works from any child process of the session. This is the declarative, correct fix.

2. **Activate dbus environment** in `sessionCommands`:
   ```nix
   ${pkgs.dbus}/bin/dbus-update-activation-environment --systemd --all
   ```
   This exports dbus/display vars to the systemd user manager so session services and spawned processes see the bus.

3. **Separate the notify-send call** from the `scrot -e` subshell — call `spawn` twice (scrot first, then notify-send) so env inheritance doesn't matter.

4. **Diagnose**: check `~/.xsession.log`, run `pgrep -a dunst`, and test the bus directly with `gdbus call --session --dest org.freedesktop.Notifications ...`.
