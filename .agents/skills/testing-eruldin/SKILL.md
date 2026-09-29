---
name: testing-eruldin
description: How to launch and end-to-end test the Godot game "Düşüş: Choralim Protocol" on this Windows machine, including debug-key hooks for long timers.
---

# Testing Eruldin (Godot 4.7 survivors roguelite)

## Launch
- Binary: `~/godot/Godot_v4.7.2-stable_win64_console.exe --path C:\Users\Administrator\repos\Eruldin` opens a windowed game on the desktop (use the window's maximize button — no wmctrl on Windows). Quote-free `~/` fails under bash — use `"$HOME/godot/..."`.
- Add `-- --probe` for the built-in autopilot (tests/probe.gd): title→kamp→arena, godmode, auto-picks drafts, screenshots to `user://probe/`.
- Add `-- --testkeys` to arm `tests/testkeys.gd` — BUT the file only loads if game.gd `_ready()` contains the two-line loader `if OS.get_cmdline_user_args().has("--testkeys"): add_child(preload("res://tests/testkeys.gd").new())`. Re-add it temporarily for a session and revert afterwards (do not commit it or testkeys.gd).
- Console build prints to a console window; capture output by redirecting to a file (`> /tmp/godot_boot.log 2>&1`). Art PNGs load at runtime → hundreds of "Loaded resource as image file" warnings are normal noise, not errors.

## Manual play flow
Title → click "VIATOR'A UYAN" → camp (WASD; E near an NPC opens dialogue; E/SPACE/click advances; ESC pause) → walk south into the glowing gate → arena run.
Controls in run: WASD + SPACE dash; weapons auto-fire. New combat keys since #323: Q yetenek, F ağır vük, R iksir, T şarap. Run start draws a "KOZ KARTI" fate card [1-3]; level-up draft is 6 cards ([1-3] picks, 4=reroll, 5=banish, 6=skip); numpad KP_1..9 also selects cards. ESC → "DURAKLATILDI" (settings incl. Parlaklık/Ekran flaşları + KAMPA DÖN + OYUNDAN ÇIK); J opens GÜNLÜK journal in camp.
- Single key taps sometimes drop during overlay transitions — prefer `hold_key ~0.3-0.5s` or re-press; F-keys are reliable.

## testkeys.gd F-key map (kept on disk, uncommitted)
F1 god · F2 time_scale 1→4→16 · F3 grant level-up · F4 lethal self-hit · F5 hitstop+level-up combo (tests pause-during-hitstop) · F6 spawn elite SENTINEL · F7 blade8+greaves evo-ready · F8 kill all (drops chests) · F9/F10/F11 director.t = 328/657/777 (miniboss/final/collapse) · F12 teleport to next arena edge N/E/S/W (arena 3400×2300).
Set `process_mode = PROCESS_MODE_ALWAYS` so keys work while paused; each fires a `[dbg]` toast for recording visibility.

## Save file + verification tricks
- Save: `C:\Users\Administrator\AppData\Roaming\Godot\app_userdata\Düşüş- Choralim Protocol\dusus_save.json` (+ `.bak` sibling since #325 — deleting the main save restores from `.bak` on next launch).
- Quit mid-run banks fragments via `run.bank_on_quit()` — works for both the OYUNDAN ÇIK button and the window X (WM_CLOSE_REQUEST); verify via choralim in the save.
- Replay intro cinematic: edit `seen_story` to remove `"intro"` (and quit first — the game rewrites the save on exit/hub).
- Boss/elite staging: F1 god first, then F9/F10 time-jump; apply keys BEFORE anything kills the player.
- Camp NPCs cluster at the campfire — stacked "E · NAME" prompts overlap there (known cosmetic issue).

## Gotchas found while testing (regression-watch items)
- Overlay leaks: a level-up draft open when victory/death fires used to leave a zombie panel; `_show_panel` frees the old overlay first. Watch any path that creates an overlay while one is open.
- The 13:00 collapse victory used to leak the boss bar + orphan boss sprites into the camp/next run; `victory()`/`_room_to` clear them now.
- Camp HUD: run elements (timer/SEV/kesim/progress) hide in camp via `_tick_hud` visibility flags — if they show in camp, check `G.state == ROOM` gating.
- Pause-safety: `create_timer(sec, false)` makes timers pause-aware; a wave/boss progressing while paused means a default-`process_always` timer slipped in.
- First-ever launch may need `--headless --import --quit` once for `.godot` caches (blueprint already covers this).
