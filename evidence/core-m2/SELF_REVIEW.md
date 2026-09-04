# M2 implementer verification

Date: 2026-09-04. Implementer: core_m2, GPT-6 Astra/max. This is bounded foundation evidence, not independent adversarial acceptance and not a game completion claim. Source baseline 4f96c7921878c93e9d465103b53d9f53d467cce9; source/evidence commits will be identified in the handoff. See README for exact engine/GPU versions and hashes.

## Logical and export evidence

`logs/core-tests.log`: 80 logical checks, zero failures and zero engine/script errors on exact Godot4.7.2. Checks exercise missing/incomplete/corrupt/checksummed/future-version saves, validated previous-copy recovery, ignored uncommitted temp, failed staging without losing old save, integer ammunition roundtrip, full settings persistence/validation/bus application, flow transitions and generation invalidation, held controls after resume, focus loss including during load completion, and passive metric aggregation. The test scene initializes the real autoload graph. Tests use a fresh isolated XDG profile and a new temporary data directory; no player profile or real save is touched.

Root separately reran the earlier70-check suite and found an untested focus-during-load defect during code review. Corrected completion to remain PAUSED until explicit focused Resume; four targeted checks bring the suite to74. This review is valuable evidence but does not substitute for the later independent native acceptance.

Additional adversarial malformed-value checks then exposed M2-002: arrays/dictionaries in boolean progress fields caused invalid-operand engine exceptions even though the validator had appended an error and test assertions continued. Preserved failing tool-output transcript: `logs/core-tests-malformed-before-fix.txt`. Fixed type guards before comparisons, covering campaign identity, anchors, equipped weapon and envelope kind too. Six regression cases bring the final suite to80. `game/tests/core/run.sh` now makes unexpected engine/script errors fatal in addition to Godot exit status. Expected invalid data returns StorageResult/errors, never an engine exception.

`logs/import.log`, `logs/export-linux.log`, `logs/export-windows.log`: import and milestone exports complete, with no script errors. Standard matching templates installed by bootstrap; isolated export profile uses a symlink to the installed template directory. Tests excluded from embedded PCK. Export binaries are generated ignored build artifacts, not committed production releases.

- Linux `build/linux/nullspace.x86_64` after M2-002 correction: ELF64 x86_64, SHA256 `e8f4927ef86d71ecb2f3b3a12ac667c6e8f2c87179e74fcd62c7a7f40aa9c4d2`.
- Windows `build/windows/NULLSPACE.exe` after M2-002 correction: PE32+ x86_64, SHA256 `1cc3207cccf8da94ee9dcf523663a2a3df257bcea42392b095b42ee84baac450`.
- `logs/linux-export-headless-smoke.log`: exported Linux binary launches and exits0 after three frames. This is not native rendering or Windows runtime proof.

## Actual native operation, self-01 and self-02

Used the separately owned native-qa harness, private rootful Xwayland and game-only named Pulse null sink. All keyboard/mouse input was directed only at `/tmp/nullspace-m2-native-self-01` or `self-02`, never the shared development fixture. Both sessions stopped with zero cleanup errors and unchanged host audio defaults. Native log confirms hardware RADV Forward+; one XIM initialization warning remains documented in `logs/native-self-02.log` (no script error/crash).

Original1920×1080 screenshots were opened, not merely generated:

| Capture | Controls / direct observation |
|---|---|
| `screenshots/01-title.png` | Native title is legible, explicitly diagnostic; missing save disables Continue. Return enters the diagnostic session. |
| `screenshots/02-settings.png`, `03-settings-saved.png` | Ordinary Tab/Space/Return navigated settings, changed VSync off and saved. UI displays stored off state and saved notice. Per-run settings snapshot retained in logs. |
| `screenshots/04-native-input.png` | W held0.8s produced diagnostic Y−0.800; mouse120/40px produced0.240/0.080 radians; left click produced one accepted edge. Counters are not a player or weapon implementation. |
| `screenshots/05-resume-held.png` | Esc paused; W and LMB were held during Return/Resume. Counter remained one and displacement remained−0.800 while harness state reported held controls. Releasing then issuing a new click produced the next accepted edge in telemetry. |
| `screenshots/06-death.png`, `07-restored.png` | F enabled flashlight, E committed circuit+checkpoint, F changed unsaved flashlight, F9 simulated death, Return restored. Restored display shows circuit=true and flashlight=true, zero transient counters, generation10. |

`video/diagnostic-input-flow.mkv`: ten-second1920×1080 H.264 recording with48kHz stereo FLAC stream,652073bytes. Captured ordinary save/pause/resume input operations; no continuous video-viewing or audio-heard claim. The fixture has no audio content. The runtime defaults to `unverified_os_input`; the harness separately identifies these as implementer adaptive native actions. These operations are neither an independent experiential playthrough nor a campaign run.

The isolated obscured Xwayland surface intermittently throttled self-01 to approximately1FPS. Early controls were still within the capture barrier and counters stayed zero; this was not reported as a successful input test. Self-02 launched with `--disable-vsync --max-fps 60`, and its telemetry already showed60FPS before settings interaction; VSync was then also disabled and saved through the actual preferences UI. The earlier suspicion that runtime settings overrode the command-line flag is not supported by those samples and is withdrawn. No performance-quality score is inferred from this 2D fixture.

Native menu operation also found that keyboard focus could move below the scroll viewport and a disabled Continue retained focus. Added `follow_focus=true` and disabled focus mode for unavailable Continue. A final native export check of these two corrections and actual X11 blur/refocus remains required before the bounded handoff is called self-validated.

## Invalid self-03 run — retained, no PASS

Linux export native attempt `/tmp/nullspace-m2-native-self-03` used pre-M2-002 binary SHA256 `38af3dad15ac5df51df1a4ecb09906e8a9a1c50337907f335222a360318f7746` and clean native harness76a9b644d4781ca92fa2fde82314a52576ed531f. After my initial Tab, before my next intended action, telemetry recorded unrequested New Game21:02:52, pause21:02:55, menu21:02:57, Continue21:03:01, pause21:03:04 and Settings21:03:06. Pointer position also changed outside my requests. Root and QA denied sending those controls; the harness has no automatic gameplay sequence. The rootful surface remained susceptible to physical input. This run is contaminated and provides NO controlled behavior PASS, including no pass for the two final diagnostic UI corrections. Supervisor/game logs retained under `logs/invalid-self-03-*`; full temporary profile retained for investigation. Root assigned a private-server input-isolation correction to QA. Native revalidation waits for that fix; no host input-device changes are authorized by this evidence task.

Current disposition: M2 source frozen for review, NOT finished or accepted. Final corrected exports built and headless-smoked; corrected native input/scroll/focus/save rerun remains pending the independent harness fix and must precede acceptance.

## Limits

M2 does not validate world anchor existence/separation, campaign topology consistency, gameplay save timing, weapon mechanics, actual camera comfort, AI fairness, audio quality, art/UI production quality, native Windows behavior, crash/power-loss durability, fresh-clone release reproducibility or any complete run. These remain later ownership/acceptance tasks. No product gate or numerical release score passes on this report alone.
