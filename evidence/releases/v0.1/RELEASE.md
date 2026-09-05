# v0.1 Raw Beta publication

User explicitly requested the current unpolished raw beta and promotion of current game work to main. This is a prerelease, not fulfillment of final game gates. No planned expansion, extra room or new interaction was implemented.

- Source/tag: `v0.1`, `83da390a2cb8ca40289db22d6dcab7c9ce4dfb95`. Gameplay remains f30b31e; only version metadata and package notes changed for the beta.
- Export command: `NULLSPACE_GODOT_BIN=<verified Godot4.7.2 binary> bash tools/build.sh all`; successful Linux and Windows exports. Engine `4.7.2.stable.official.ed1daf0bf`.
- Linux native smoke: isolated existing QA runner `/tmp/nullspace-v01-smoke`, scripted diagnostic. Opened full-resolution menu and gameplay PNGs; real Return, forward input and Escape exercised. Process then stopped through owned cleanup. No fresh full-playthrough or audio-listening claim. One XIM initialization warning; no engine/script errors observed in game.log.
- Prior source-equivalent functional run: evidence/section/solo-e/unarmed-export-02 (54.33 active seconds, not target-duration proof).
- Windows cross-export only; no native Windows validation.
- Archives verified: eight expected files each, ZIP CRC check clean, executable mode retained in Linux tar. Instructions, build source, checksum, credits and full engine/license notices included.
- Public release: https://github.com/marius4lui/NULLSPACE/releases/tag/v0.1 ; prerelease=true, draft=false, not marked latest stable.
- Main fast-forwarded to current solo game source, preserving history. Old unaccepted worktree branches were not blindly merged.

Archive SHA256:

```
153f366946950cd03aa25adbc61290ab3ee49b0665f88f4f7d1ab6da36625fc4  NULLSPACE-v0.1-linux-x86_64.tar.gz
9e8ab06e3c2df7f36113badb5f7ab78a2901a07cb4ef886cde2712cf73564f77  NULLSPACE-v0.1-windows-x86_64.zip
```

Final duration, atmosphere, listening, tuning and full-release checks remain open. The release notes state these limitations. README and existing website are updated factually with the beta download and current main source.
