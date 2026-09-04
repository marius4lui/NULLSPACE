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

Wake up on damp carpet beneath fluorescent lights. Somewhere inside an impossible commercial building, an exit is waiting for power. Find three relay stations, restore the circuit, and remember your way back.

Something else is learning the building with you.

## The intended experience

- **One persistent threat.** The Listener is a tall, original creature designed to observe, stalk and search using sight, sound and imperfect memory.
- **Every shot has a cost.** A compact pistol and pump shotgun buy time, but their noise gives away your position. Doors, cover and route choices matter.
- **Six connected sectors.** From faded office grids and exposed open-plan rooms to service corridors, blackout and the Red Threshold.
- **Architecture you almost remember.** Rare changes happen out of sight. Familiar landmarks remain your best chance of getting home.
- **A complete escape.** Three relays, a final phase breaker and a return to the exit. Progression is designed to remain possible without ammunition.

These describe the intended game; implementation is still in early production.

## Built with GPT-6 Astra

NULLSPACE is an AI-developed game created with **GPT-6 Astra through Codex**, under the direction of [marius4lui](https://github.com/marius4lui). AI agents handle implementation and original asset creation, with separate review and in-engine testing. This repository follows the development of the game, from its first rooms to a playable release.

## Specifications

| | Target |
| :--- | :--- |
| Engine | Godot 4.7.2 · Forward+ |
| Asset pipeline | Blender 5.2.1 LTS · original models, materials and animation |
| Platforms | Windows and Linux, x86-64 |
| Campaign | 35–60 minutes · 56 authored spaces · 6 sectors |
| Arsenal | Semi-automatic pistol · pump-action shotgun |
| Threat | The Listener · approximately 2.3 m tall |
| Performance goal | 1080p / 60 FPS on RTX 2060 or RX 6600-class hardware |

The performance target has not been validated on that hardware. Minimum system requirements are not established yet.

## Current state

There is **no downloadable playable campaign yet**. Separate development worktrees contain a walkable environment preview, a rigged Listener with three initial animation clips, and core systems for settings, saves and game state. Weapons, creature behavior and campaign integration remain in development. These candidates have not all passed independent acceptance.

The published `main` branch contains the website, design, development records and this preview image. It is not yet a runnable Godot project. Build, launch and game-control instructions will accompany the integrated game.

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
