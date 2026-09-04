# Section-base staging candidate

2026-09-05. Staging succeeded; this is **not Section A acceptance** and does not yet make the room playable. No main promotion or native operation occurred.

## Exact inputs

Created `agent/section-base` in the sibling `section-base` worktree from main `552c340bcbeae64552ad76bdb2eaddf70795a732`, following the user-authorized strategy amendment. Four sequential, conflict-free merges produced code candidate `bbd8b5ba442aefa733c7896784c35239dcf93a09`:

| Existing component | Exact input | Merge commit |
|---|---|---|
| Accepted native runner | `5389c4c26fa8a22669c9cec7eace06796170fd4c` | `e008fb7eb226dbaf92b6f342f30b51f08db0c1b8` |
| M0 toolchain | `b647a1eb1b8e7903844dda87947e6cc919dfe1c4` | `b16a69557bf972750964604ba8fbf12e39975aaa` |
| Existing core and additional self-evidence | `988c18b056e18963e8c420ae8960ede616dbbf2b` | `a749744c6b69de78b2c8834d86184081e9166526` |
| Existing original environment | `e70fec58d379b90b28d4fd3343e054e7c201965e` | `bbd8b5ba442aefa733c7896784c35239dcf93a09` |

Core `988c18b` differs from requested earlier `7923b80` only by evidence; `game/` is unchanged and remains source `891344e`. No code, assets or tests were rewritten, regenerated or fixed in staging. Historical evidence remains intact.

## Bounded verification

Using `/home/marius/.local/share/nullspace/toolchains/godot-4.7.2/Godot_v4.7.2-stable_linux.x86_64`, exact `4.7.2.stable.official.ed1daf0bf`:

- One headless editor import exited 0, with no script, parse or engine errors. See [import.log](import.log).
- One existing `game/tests/core/run.sh` invocation exited 0: **256 checks, no failures**. See [core-tests.log](core-tests.log).
- Its existing 30/60/120 render-scheduling probes each passed at 60 physics ticks and one second of simulation. These are headless logical results, not native frame-rate measurements. See [30](core-tests-rate-30.log), [60](core-tests-rate-60.log), [120](core-tests-rate-120.log).

Commands ran from the section-base worktree. The import used a fresh `mktemp` XDG data/config/cache profile and `timeout --kill-after=5s 180s`, followed by:

```sh
godot --headless --editor --path game --import --log-file /absolute/section-base/evidence/integration/section-base/import.log
bash game/tests/core/run.sh /absolute/path/to/Godot_v4.7.2-stable_linux.x86_64 /absolute/section-base/evidence/integration/section-base/core-tests.log
```

Here `godot` denotes the exact binary above, and `/absolute/section-base` is `/home/marius/Projekte/Dev/NULLSPACE-worktrees/section-base`. The unmodified test wrapper creates its own isolated temporary profiles. Import left no tracked source changes.

The strategy, contracts, gates, root state/design documents, README, existing public web files and `.github` are unchanged from the selected main base. Main subsequently advanced independently to governance-only `051d4f5`; it was not overwritten or promoted by this task.

## Concrete next handoff

Reuse `res://environment/m4_reference_room.tscn`, which instantiates the authored room assets, collision boxes, fixtures and surface library. The current main scene is still `res://scenes/bootstrap/diagnostic_boot.tscn`: a concrete Player and shared playable scene are missing. Core owns the next isolated Section A implementation and its actual native run. The merged `tools/qa/native.py` provides the previously accepted isolated input/capture runner; no new launcher is needed.

No new native session was launched here, and the GPU is free. Native gameplay, movement/collision/flashlight/interaction/pause behavior, material/performance quality and coherent Section A acceptance remain unverified. Previous audio-listening, native Windows and target-GPU limitations remain open. These are not reasons to postpone assembling and testing Section A.
