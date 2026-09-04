# M2 foundation evidence

Worktree: agent/project-skeleton based on 4f96c7921878c93e9d465103b53d9f53d467cce9. Implementation/evidence commits recorded in final review report. No campaign, production gameplay/art/audio/UI, release score or full-playthrough pass is claimed.

Exact runtime: Godot 4.7.2.stable.official.ed1daf0bf, binary SHA256 8d106cbe6144c2dc7e881d61d2429c1a8a76e6b22ef48bd5e48dcf934953f71e. GPU probe/native log: AMD Radeon 660M, RADV Mesa26.1.8, Vulkan1.4.354, Forward+. Host is integrated GPU; no target discrete-GPU performance proof.

Read `docs/CORE_INTERFACES.md` for API contracts, data validation, diagnostic controls and remaining domain validation requirements. This directory contains logical-test logs, milestone export logs, native window captures and a concise reviewed observation report. Captures are original resolution, not production art evaluations.

Native harness belongs to the separate native-qa worktree. Its per-run XDG profile, private Xauthority and named audio sink isolate game data/capture/input. Do not copy credential cookies, authority files or profile caches into the repository. Logs/captures name only in-scope game artifacts. Raw temporary runs `/tmp/nullspace-m2-native-self-01` and `/tmp/nullspace-m2-native-self-02` retain detailed supervisor evidence while this goal is active.

Development defects found and corrected: JSON numeric type drift across roundtrip; future version overwrite prevention; focus loss while LOADING must finish PAUSED; malformed-data type guards before comparisons (M2-002); settings keyboard focus must scroll into view; disabled Continue should not retain keyboard focus. Eighty final logical checks pass with an explicit engine-error scan. Final native revalidation remains pending because self-03 received unrequested inputs and is invalid evidence. Source may be reviewed but M2 is not finished/accepted. No arbitrary numeric quality scores are assigned.
