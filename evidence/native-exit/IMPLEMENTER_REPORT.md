# QA-007 owned-window natural-exit correction

Implementer: qa_native, GPT-6 Astra/max. Date: 2026-09-04 UTC. **Self-validation complete; separate adversarial acceptance still required.** This report does not self-accept the harness, accept M0, or assign any game quality score.

Source: `f34e03e` adds the bounded exit lifecycle and diagnostic tests on accepted source/evidence `a98fede`; `fb3a09d` changes only the native proof driver's launch boundary. All final native runs below identify clean `fb3a09d`. Original native-seatfix and M0 source branches remain unchanged. Public evidence is hashed in `SHA256SUMS`; profile caches, runtime cookies and private sockets are excluded.

## Failure and correction

The unchanged original M0 failure is committed at independent review `68ba035`, under `evidence/reviews/toolchain/native-final-01`. Escape destroyed the verified game window before its process finished exiting. The old safety thread's property query raised BadWindow for exactly that window, marked provenance invalid, and sent SIGTERM. The child returned -15 and its buffered stdout was lost. Prior independent native acceptance covered explicit stop/signals/recovery, not this window-first natural-exit path.

The correction recognizes only a BadWindow whose resource equals the previously verified game XID, which is now absent from the same private root with no mapped foreign window present. It checks the exact owned Popen PID/start identity, immediately cancels input and releases runner-held controls, then publishes `closing` and allows that child a fixed two-second exit grace. The deadline is not extended by later requests/errors. New input, focus and captures are refused during grace; status, release and explicit stop remain available. XI2 and foreign-window checks continue in the safety thread, as does timeout enforcement. Nonzero exit, windowless timeout, changed PID identity, wrong resource, hidden-but-existing window and foreign/seat faults remain failures. Explicit stop/signals still cancel holds and terminate owned resources normally.

The shared X connection remains guarded by GameWindow's reentrant lock. Lifecycle transitions and manifest writes share a separate reentrant lock so safety and command threads cannot race the state-file temporary path. Input cancellation is checked before focus or XTEST press; a pending tap/hold wakes on cancellation. Teardown stops and joins the safety thread before closing X connections, as before. Neither the 50 ms sampling target nor the two-second grace is an arbitrary-stall hard-real-time guarantee.

## Actual native exit evidence

`proof-02/exit-verification.json` records **38 passing checks** across seven fresh isolated sessions, 22:30:05.244–22:30:26.939 UTC. Host versions, exact source hashes, private process/socket/device identities, application hashes and commands are in each run's launch/state files.

The new `fixtures/window_exit.py` is a minimal original X11 lifecycle diagnostic, not a game renderer. It receives real native Escape or a click on its visible Quit area, destroys its own window, then remains alive 0.4 seconds before normal exit. During the gap it queries only that private X server's actual key bitmap and records it. A stdout marker is intentionally buffered until process shutdown. The fixture refuses to run outside the owned inputless compositor.

| Scenario | Observed result |
|---|---|
| `escape` | Actual W+Escape pressed; all private keys released 51.2 ms after destruction; child exit 0; buffered stdout preserved; stopped cleanly. |
| `quit-click` | W held while an actual native click chooses Quit; empty key bitmap after 25.8 ms; child exit 0 and stdout preserved. |
| `nonzero` | Empty key bitmap after 25.9 ms; child's real exit 7 and stdout preserved; session correctly **failed**, not normalized to success. |
| `windowless-timeout` | Empty key bitmap after 51.3 ms; child intentionally remains alive three seconds; fixed two-second grace expires, owned child terminated, session correctly **failed**. |
| `foreign-during-grace` | Empty key bitmap after 26.0 ms; fixture deliberately maps an additional private window labelled with a nonmatching PID after grace begins; foreign-window guard terminates the owned fixture and correctly **fails**. No host window or process was touched. |
| `godot-export-01`, `godot-export-02` | Actual clean M0 Linux export, two fresh profiles, native Space/A/F/F12/Escape; both natural exits 0; full logs flush and confirm Forward+ / AMD Radeon 660M RADV. Each paused/lamp-off native PNG precedes its viewport readback and matches every 1920×1080 RGB pixel. |

Every scenario has no cleanup errors, no remaining owned PID/runtime after read-only verification, unchanged host audio defaults, and only XTEST raw sources. Expected negative scenarios remain failed in their original manifests; the enclosing diagnostic passes because they fail for the requested reason. The M0 export SHA256 is `c75d780ed3024047a83d281338d15fbf2c5043728892eb62170c20d58bb86dbd`, from clean source `9bdcfc35be84020f4340e5f727893793e409df5e`; this correction's use of it is self-test evidence, not the separate final M0 verdict.

Opened at original 1920×1080: `proof-02/escape/01-native-quit.png`; both Godot runs' `viewport-000-initial.png` and `01-native-paused-lamp-off.png`. The native Quit area is visible in the X11 diagnostic. The Godot originals show the three imported beveled meshes/materials, initially lit and animated, then a changed camera view with lamp contribution removed and animation-speed HUD 0. The matching reference files are retained. No production art or animation-quality claim is made.

## Existing native regressions

`proof-03-regression` uses the unchanged input/render/audio fixture on exact clean `fb3a09d`: all **14** input, **8** objective media, **7** full-RGB freshness pairs and **15** native safety checks pass. It exercises simultaneous W+D+Shift, captured relative mouse, fire, menu/pause/resume rejection, explicit/lease releases, partial and drip-fed IPC, capture burst, long hold, private-root focus loss, and SIGTERM during a ten-second hold. Actual application release times for 200 ms leases were 257.5 ms (partial IPC), 245.8 ms (drip IPC), 229.5 ms (capture burst) and 239.9 ms (long hold). Ten genuine captures span the release test; no fake slow capture is inserted. SIGTERM interrupted the hold and completed cleanup in 536.9 ms.

The retained ten-second `input-proof.mkv` has 600 encoded 1920×1080/60 Hz frames and 48 kHz stereo FLAC. Quiet-channel frequencies are 440 Hz left / 660 Hz right, peaks 0.34497 / 0.34470, and the three audio-minus-video pulse offsets are 48 / 57 / 53 ms, within the unchanged 150 ms diagnostic tolerance. These metrics and sampled frames are not listening or continuous experiential video review. The root runtime has already rejected actual AudioContent input; audio was not heard.

Opened all seven original `freshness-*.png` frames. They show shot 3→4→5 with expected changing camera/mouse totals, paused/menu capture false, resumed capture true, then shot 6 with another actual camera change. Also opened `06-lease-during-capture.png` and the last `06-lease-burst-09.png`: position changes during the real capture/release interval are visible. Opened three full-resolution `video-shot-*.png` frames extracted 50 ms after each detected pulse onset; they show actual flash markers and shot 1→2→3 with changed positions. This is sampled temporal corroboration, not an uninterrupted gameplay assessment.

`proof-04-explicit-stop` additionally holds W in the actual X11 fixture, invokes the documented `native.py stop` CLI, observes the fixture's native W release, then verifies stopped status, exit -15 explicitly attributed to stop, no natural-exit phase, clean resource removal and unchanged defaults. All four checks pass.

## Reproduction and preserved development failures

From this worktree:

```sh
python3 -m unittest discover -s tools/qa/tests -v
python3 tools/qa/prove_exit.py \
  --run-root /absolute/new/evidence-directory \
  --godot-export /tmp/nullspace-m0-independent-tVzIFF/source/tools/bootstrap/output/linux/nullspace-bootstrap.x86_64
```

The offline suite has 22 passing checks (`unit-checks.log`); its X resources are test doubles and its child-process exit checks use real owned Python processes. It explicitly covers wrong/unverified/still-existing resources, PID/start mismatch, refusal of new controls, grace expiration, foreign and seat failures, nonzero exit, buffered exit 0, concurrent lifecycle/manifest writes and prior safety/freshness tests. The first test-double draft lacked an Xlib resource decoder and was corrected; no production criterion was removed.

For the existing full fixture regression, use the documented `native.py start` at a fresh run directory, then `prove_fixture.py`, `analyze_fixture_media.py`, `prove_freshness.py`, and `prove_safety.py` in that order. The last command intentionally ends the owned session with SIGTERM. Exact commands are preserved in `proof-03-regression/launch.json` and request/event journals. An initial local driver import failed before any input dispatch; rerunning with the correct tool-module path performed the recorded sequence unchanged.

`proof-01` is retained as a failed **test-driver cleanup assertion** on `f34e03e`. Its first actual native Escape already exited 0, released keys and flushed stdout, and all resources were removed. However, the proof embedded `native.start()` inside its own long-lived process, leaving the completed detached supervisor as its unreaped child until Python's next Popen/parent exit. `fb3a09d` changes only that driver to invoke the documented CLI process boundary. It does not lengthen the cleanup bound, ignore live PIDs, change the lifecycle fix, or convert the failed record to PASS. Fresh `proof-02` passes the unchanged cleanup checks.

All GPU sessions were stopped before handing the lease to core_m2. The exact correction must now receive separate bootstrap_m0 review before integration or a fresh independent M0 acceptance run. Native Windows, target discrete-GPU performance, audio listening and all product/release gates remain outside this bounded infrastructure evidence.
