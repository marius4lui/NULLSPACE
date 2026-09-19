# v0.3.1 — Windows Start Hotfix

Issue [#5](https://github.com/marius4lui/NULLSPACE/issues/5) reported that a new
Windows campaign opened on the pause screen with **Resume** before gameplay began.
Telemetry from v0.2 reproduced a zero-time `arrival_wake` restore followed by
`load_ready_unfocused` and PAUSED. The cause was the native focus value sampled
before the Windows game window became active and retained until load completion.

Runtime source and tag target:
`63140a7b943bba620d6eb5b5a665d09380a6171c`. The fix refreshes the actual native
window focus in `GameFlow.complete_load`; headless tests keep explicit control of
both focus branches and genuine focus loss still produces PAUSED. Version is
`0.3.1-beta-unstable`; Android versionCode is 5, but no Android package was rebuilt
or published for this desktop hotfix.

## Validation

- Godot 4.7.2 stable core suite: **260/260 checks pass**.
- Fixed logical clock probes at 30, 60 and 120 render frames: all pass with 60
  physics ticks and 1.0 simulated second.
- Fresh Windows release export was launched with an isolated user profile. Its
  local telemetry recorded MENU -> LOADING (`new_game`) -> PLAYING (`load_ready`),
  `focused=true`, `paused=false`, at zero simulation time. No
  `load_ready_unfocused` event occurred. The process then shut down cleanly.
- The reporter separately launched the same release build with the normal profile
  and confirmed that Start enters gameplay correctly.
- Windows ZIP was fully streamed, its embedded executable checksum matched, and
  `BUILD_INFO.txt` identified the runtime source commit.
- Linux TAR.GZ passed gzip/readback checks, identified the same source commit, and
  stored `nullspace.x86_64` with executable mode. It was cross-exported on Windows;
  native Linux execution was not repeated for this hotfix.

## Published release

Release: [v0.3.1 Windows Start Hotfix](https://github.com/marius4lui/NULLSPACE/releases/tag/v0.3.1).
It is public, `prerelease=true`, and `draft=false`.

| Asset | Bytes | SHA-256 |
|---|---:|---|
| `NULLSPACE-v0.3.1-windows-x86_64.zip` | 95,699,933 | `0cbc99edc361ed802f2f8a94ce986e686e71af41d5987f3eafae90af427d0522` |
| `NULLSPACE-v0.3.1-linux-x86_64.tar.gz` | 85,711,207 | `9089f0dd8ebb6a4eb2273b9c8dcdcf6f7a0dd503a61821c291d0aa28a372bd5e` |
| `SHA256SUMS` | 207 | `47f974c8d39dc8f123596bc105f430a7b7cf12fda39c55dafde04511e7a24707` |

GitHub's reported asset size and digest matched each local release file after
publication. Existing v0.3 gameplay, duration, listening and platform-acceptance
limitations remain; this release claims only the scoped startup correction and
the validation above.
