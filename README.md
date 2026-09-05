<div align="center">

# NULLSPACE

**You have a weapon. The building has ears.**

Single-player · First-person survival horror · In development

[![Development: early production](https://img.shields.io/badge/development-early_production-d6c77c?style=flat-square&labelColor=20221e)](STATUS.md)
[![Engine: Godot 4.7.2](https://img.shields.io/badge/engine-Godot_4.7.2-899e93?style=flat-square&labelColor=20221e)](ARCHITECTURE.md)
[![Target: Windows and Linux](https://img.shields.io/badge/target-Windows_%2B_Linux-b6b8ae?style=flat-square&labelColor=20221e)](#specifications)

**[Explore the website](https://github.marius4lui.dev/NULLSPACE/)** · [Game design](GAME_DESIGN.md) · [Development status](STATUS.md) · [Discussions](https://github.com/marius4lui/NULLSPACE/discussions)

</div>

[![Early NULLSPACE environment render: empty fluorescent-lit rooms, faded wallpaper and stained carpet](docs/images/environment-preview.png)](https://github.marius4lui.dev/NULLSPACE/)

*Early Blender environment render using original project assets. Work in progress.*

Wake up on damp carpet beneath fluorescent lights. Somewhere inside an impossible commercial building, an exit is waiting for power. Find two power switches, restore the exit, and remember your way back.

Something else is learning the building with you.

## The intended experience

- **One persistent threat.** The Listener is an original creature that follows sight and sound clues, searches, and can lose your trail.
- **Every shot has a cost.** A compact semi-automatic pistol buys time, but its noise gives away your position. Doors, cover and route choices matter.
- **A compact connected building.** Roughly 8–12 meaningful rooms: quiet arrival, nested offices, short service/blackout and the return to the exit.
- **Architecture you almost remember.** Offset openings, sparse landmarks and tactical doors help you navigate and escape.
- **A complete escape.** Two separated power switches and a return to the exit, designed for a 10–15 minute first successful run. Progression is designed to remain possible without ammunition.

These describe the intended game; implementation is still in early production.

## Built with GPT-6 Astra

NULLSPACE is an AI-developed game created with **GPT-6 Astra through Codex**, under the direction of [marius4lui](https://github.com/marius4lui). One agent now handles implementation, original asset creation and practical in-engine checks, reusing the existing work. This repository follows the development of the game, from its first rooms to a playable release.

## Specifications

| | Target |
| :--- | :--- |
| Engine | Godot 4.7.2 · Forward+ |
| Asset pipeline | Blender 5.2.1 LTS · original models, materials and animation |
| Platforms | Linux laptop first; Windows x86-64 cross-export when available |
| Game | 10–15 minutes · approximately 8–12 connected rooms · two switches |
| Equipment | One semi-automatic pistol · battery-free flashlight |
| Threat | The Listener · approximately 2.3 m tall |
| Performance | Laptop profile measured on Radeon 660M; see [actual measurements](PERFORMANCE.md), no other-hardware guarantee |

Minimum requirements are not established yet. Performance will be reported with the actual laptop, resolution and profile. A Windows cross-export is not native Windows validation.

## Current state

The `feat/short-game` development branch now joins the original rooms, Player, pistol, Listener, doors, both power switches, safe checkpoints and ending in one playable scene. A native diagnostic route reached the ending with inspection pauses. **This is not a finished release:** natural first-play duration, atmosphere/audio, final export checks and remaining defects are open. The known diagnostic route is substantially shorter than the 10–15 minute target; pauses are not counted as playtime.

The public `main` baseline remains documentation-only until the integrated branch is verified and promoted. Existing worktrees/evidence are preserved; development continues solo.

## Run and build the development branch

With Godot **4.7.2 stable** and its matching export templates installed:

```sh
git clone --single-branch --branch feat/short-game https://github.com/marius4lui/NULLSPACE.git
cd NULLSPACE
godot --editor --path game --import --quit
godot --path game
bash tools/build.sh linux
./build/linux/nullspace.x86_64
```

For an official portable Godot binary, set `NULLSPACE_GODOT_BIN` to that executable when invoking `tools/build.sh`. Use `windows` or `all` instead of `linux` for cross-exports. Production assets are checked in; Blender is not required to reproduce a game export. Source asset generators live under `tools/art/` and use the retained originals under `art/source/`.

Controls: WASD, mouse, Shift sprint, Ctrl crouch, F flashlight, E interact, left mouse fire, R reload, Escape pause. Settings cover audio, mouse/invert/FOV, display, VSync/FPS cap and reduced motion/flashes. See [playtest instructions](docs/PLAYTEST.md), [credits](CREDITS.md) and [licences/notices](LICENSES.md). Linux is the tested platform; Windows export is not native validation.

## Explore and contribute

| Looking for… | Start here |
| :--- | :--- |
| The world, creature and combat | [Game design](GAME_DESIGN.md) · [Art direction](ART_DIRECTION.md) |
| Technical decisions | [Architecture](ARCHITECTURE.md) · [Decision log](DECISIONS.md) |
| Current work and limitations | [Status](STATUS.md) · [Issues register](ISSUES.md) · [Next production steps](docs/NEXT_PRODUCTION_ACCEPTANCE.md) |
| Website source and local preview | [`site/`](site/) · [Website guide](docs/WEBSITE.md) |
| A bug report or suggestion | [Open an issue](https://github.com/marius4lui/NULLSPACE/issues/new/choose) · [Join a discussion](https://github.com/marius4lui/NULLSPACE/discussions) |
| A contribution or security report | [Contributing](CONTRIBUTING.md) · [Security](SECURITY.md) |

Original production assets are being created for NULLSPACE, with editable sources and generation/export records. No downloaded game-content packs are used. No release date has been announced.

<div align="center">

**[Enter NULLSPACE →](https://github.marius4lui.dev/NULLSPACE/)**

</div>
