# Saved difficulty flag validation

Issue: [#6](https://github.com/marius4lui/NULLSPACE/issues/6). Base source:
`d3bd07406fab423b4bf4201009e5c7fd6336e18c`. Automated checks on 2026-10-21.

Ending validation interpreted difficulty and emergency circuit flags before their
types were checked. Malformed snapshots were rejected eventually, but emitted
GDScript errors. World validation now runs first; dependent ending checks run only
after the prerequisite validations succeed. Save format and valid-game rules are
unchanged. This is a robustness fix, not a demonstrated security vulnerability.

## Verification

- Official Godot 4.7.2, engine `ed1daf0bf001b61586d9930840f2f1394092c079`.
- Added 71 checks: malformed flags in all four modes, valid completed snapshots,
  recovery of a valid backup, and byte preservation after a rejected write.
- The new regressions against the original validator make `tests/core/run.sh`
  fail with exit 1 and 40 script errors, despite the rejection assertions passing.
- After the fix, the core runner passes 331 assertions with no script/engine
  errors, plus its 30/60/120 render-scheduling probes.
- A separate 708-case snapshot/settings mutation probe completed without
  script/engine errors after the fix (15 errors before). These are mutation
  trials, not 708 semantic assertions.

The tests used isolated HOME/XDG locations and synthetic saves. The core-only
fixture retained the repository's autoloads, resources, audio-bus layout and
tests, with its main scene set to the core runner. An initial incomplete fixture
lacked the bus layout; that fixture error was corrected before the recorded
pass. The committed tests also run through the existing full-project core runner.

No live saves, network attacks, native game runs, device performance, audio
listening or release acceptance are claimed. No gameplay mechanics changed;
existing full-game and Android acceptance gaps remain open.
