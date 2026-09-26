---
name: testing-eruldin
description: How to launch and end-to-end test the Godot game "Düşüş: Choralim Protocol" on this Windows machine, including debug-key hooks for long timers.
---

# Testing Eruldin (Godot 4.7 survivors roguelite)

## Launch
- Binary: `~/godot/Godot_v4.7.2-stable_win64_console.exe --path C:\Users\Administrator\repos\Eruldin` opens a windowed game on the desktop (1280x720; use the window's maximize button — no wmctrl on Windows).
- Add `-- --probe` for the built-in autopilot (tests/probe.gd): title→kamp→arena, godmode, auto-picks drafts, screenshots to `user://probe/`.
- Console build prints to a console window; capture output by redirecting to a file (`> /tmp/godot_boot.log 2>&1`).

## Manual play flow
Title → click "VIATOR'A UYAN" → camp (WASD move; E near an NPC opens dialogue; E/click advances; ESC pause) → walk south into the glowing portal → arena run.
Controls in run: WASD + SPACE dash only; weapons auto-fire. Level-up opens a 3-card draft (keys 1/2/3 or click). Chests open on walk-over. ESC → "DURAKLATILDI" panel (settings + "KAMPA DÖN").

## Debug harness for long timers
Bosses fire at 5:30 / 11:00 / collapse 13:00 — too long for manual testing. A temporary `tests/testkeys.gd` F-key harness (F1 god, F2 time_scale, F3 force level-up, F4 lethal self-hit, F5 victory, F6 spawn elite, F7 evo-ready blade8+greaves, F8 kill-all, F9/F10/F11 jump director.t) plus a two-line loader block in game.gd gated on `-- --testkeys` was used for this session — check if tests/testkeys.gd still exists before relying on it; recreate from that pattern if needed. Godot processes F-keys via `_unhandled_key_input`; set `process_mode = PROCESS_MODE_ALWAYS` so keys work while paused.

## Gotchas found while testing (fixed in PR #2 — regression-watch items)
- Overlay leaks: a level-up draft open when victory/death fires used to leave a zombie card panel; `_show_panel` now frees the old overlay first. Watch for any path that creates an overlay while one is open.
- The 13:00 collapse victory used to leak the boss bar + orphan boss sprites into the camp/next run; `victory()`/`_room_to` now clear them. If bosses reappear in camp, check the world-children sweep in `Run._room_to`.
- Camp HUD is reset by `hub_ui(true)`; stale timer/kesim after a run means that reset path broke.
- Meta save: `user://` → `C:\Users\Administrator\AppData\Roaming\Godot\app_userdata\Düşüş- Choralim Protocol\dusus_save.json` — check deaths/kills/choralim/victories there to confirm run end paths.
- First-ever launch may need `--headless --import --quit` once for `.godot` caches (blueprint already covers this).