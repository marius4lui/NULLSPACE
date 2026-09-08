# NULLSPACE — current goal contract

## Android scope amendment — 2026-09-08

User explicitly approved implementation of the complete Android plan. Android is now the primary release target: signed offline APK, Android 12/API31+, ARM64, current flagship/8GB RAM target, touch-only operation, Mobile renderer, Standard 60 FPS and Battery saver 30 FPS. No Play Store or controller work. Existing complete-game content and fairness requirements remain; preserve Desktop behavior and original assets. SDK/toolchain, signing identity and build steps must be reproducible. Keep signing secrets outside Git. Android installation/update, multitouch, safe areas, Back, interruption/resume, safe checkpoint recovery, real listening, 30-minute thermal performance and two final exported full runs are required. Real first-play 10–15 minute duration is still open. Emulator and headless checks are supporting evidence only. Device not yet connected at amendment; no Android hardware claims. Earlier Linux-first delivery priority is replaced, not a fixed defect. One agent works sequentially on feat/short-game; main remains unchanged until acceptance.

Authority: user's explicit final scope and working-method replacement on2026-09-05. This replaces contradictory earlier instructions including freezes, mandatory delegation and the35–60minute campaign. Prior complete contract/records are preserved verbatim once in docs/history/pre-scope-change-2026-09-05/ and Git. Historical conditions are not current blockers.

Active feature-branch addendum (2026-09-05): `feat/difficulty-room1` keeps this same Room 1 and adds Easy, Medium, Hard and Nightmare. Easy requires Office A; Medium retains the two-switch baseline; Hard and Nightmare require Office A, Service B and a local Emergency C interaction. This explicit difficulty objective supersedes the two-switch-only line below for this branch; it does not authorize new rooms, monsters, weapons or a general difficulty framework.

## Goal

Complete good, budget-conscious single-player first-person survival horror, approximately10–15minutes for a meaningful first successful run. Two months is an upper horizon, not time to exhaust. No prototype/compilation/partial scene counts as completion. One GPT-6 Astra agent implements solo; no new subagents or independent-agent reviews. No model/purchase/account/reset changes without explicit instruction. Preserve existing work; selective reuse, not restart or blind bulk merge.

## Required game

- About8–12meaningful connected rooms. Rhythm and measured duration decide; no artificial waiting, long empty routes or repeated objectives.
- Quiet arrival with initially unpowered exit, nested offices, short service/blackout, return to activated exit.
- One original Listener, one semi-auto pistol, flashlight without batteries, tactical doors.
- TWO separated power switches then escape. No extra phase switch/boss/required kill. Shots buy time; zero-ammo escape remains possible.
- Clear brief environmental introduction, definite short ending/credits, death/restart/fair checkpoints.
- Responsive controls/fire; fair comprehensible creature; coherent rooms/light/spatial sound; stable complete flow; usable menus/settings.
- Listener FSM: roam/investigate/chase/search/attack/stagger/retreat. Real navigation/LOS, sound clues, dated and decaying last credible position. After sight loss investigate old clues then end search. No wall vision/attacks, hidden continuous tracking or teleport-to-player.
- Only actually used animations, reusing original model/rig/clips and sensible blends.

## Technical and delivery scope

Godot4.7.2 and existing tools; concrete scenes, typed references/signals, few Resources. Reuse tested save/state/input/time/settings and useful tests. No core rewrite or universal infrastructure absent demonstrated need.

Small saves: two switches, consumed pickups, player state/ammo and safe checkpoint. Fair Listener reset. Menus Start/valid Continue/Settings/Pause/Death+Restart/End+Credits. Settings volume, sensitivity, invert, FOV, window/fullscreen, resolution or render scale, VSync/FPS cap, reduced motion/flashes. Two graphics profiles suffice.

Linux on user's laptop first; measure actual settings/FPS/frame times, no other-hardware claims. Windows export if existing toolchain supports it; missing native Windows testing does not block tested Linux completion. Reuse original assets/audio, no content packs/copied franchise assets. Standard/licensed fonts allowed with notices; new assets only as needed.

README and existing website factual/public scope correction is authorized, not redesign/marketing expansion.

## Removed by scope change, NOT fixed

56rooms/six complete sectors; shotgun; third relay/phase/boss; required shifting geometry; general horror director;17clip quota; original font pipeline; large diagnostics/frameworks; numerical quality scores; delegation/independent-agent gates. Preserve useful existing work. Already-safe anomaly may remain, but no new system required.

## Completion — all required

1. Full start-to-ending works; first successful run about10–15minutes without padding.
2. Movement, pistol, Listener, doors, both switches and checkpoints actually checked together.
3. No known crash, softlock, save corruption or severe gameplay defect.
4. Coherent usable laptop graphics/sound, honest modality/validation limits.
5. Reproducible Linux release export exists and is launched/tested; matching controls/build/launch/limits/credits/licenses/evidence.
6. TWO full successful runs after last gameplay change, source/hash/duration/outcome documented. Same agent/user permitted. Automated runs labelled, not evidence of heard audio or subjective feel.

Keep meaningful tests; narrow new coverage to real control/ammo/damage/door/switch/save/restart/completion risks. Never disable failures, fake tests/impressions or call a compiling build finished.

## Stored Goal limitation

Available tools read/create goals or mark complete/blocked, but cannot edit an unfinished objective or resume usageLimited. The old stored objective remains uncompleted, not falsely achieved. Per user fallback, continue under this updated repository contract.
