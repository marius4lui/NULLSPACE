# Contributing to NULLSPACE

Useful bug reports, clear design feedback and small, focused improvements are welcome.

NULLSPACE is in early production. Public `main` contains the website, original preview image and project documentation. Existing gameplay and asset work is preserved while a single implementer connects the reduced 10–15 minute game; there is no integrated public game to build or play yet.

## Pick the right place

- Use [Issues](https://github.com/marius4lui/NULLSPACE/issues/new/choose) for a reproducible problem or a concrete improvement.
- Use [Discussions](https://github.com/marius4lui/NULLSPACE/discussions) for questions and broader ideas.
- Follow [SECURITY.md](SECURITY.md) for sensitive security findings.

Check existing issues and [the development issue register](ISSUES.md) first. A useful report says what you tried, what happened, what you expected, and which page or commit you used. Screenshots and short recordings help; remove personal information and credentials before attaching them. Mention your browser and screen size for website problems, or OS, GPU, graphics settings and build for a future game report.

## Make a focused change

1. Read [the current status](STATUS.md) and the relevant design document. The game scope in [GOAL_CONTRACT.md](GOAL_CONTRACT.md) and [QUALITY_GATES.md](QUALITY_GATES.md) is frozen.
2. Start a branch from `main`. Discuss substantial gameplay or asset proposals before investing in them; a project-wide license has not been selected yet.
3. Keep the change limited to one purpose. Describe the player or reader benefit and any known limitations.
4. Validate what you changed. Website edits need a real browser check at desktop and mobile widths; use the [website guide](docs/WEBSITE.md). Documentation links should resolve. Gameplay changes require the relevant build, real interaction and inspection evidence. Current project development is solo; independent-agent reviews are not required.
5. Open a pull request with the exact checks you performed and screenshots for visible changes.

Do not present planned work as a released feature or a technical check as proof of game quality. Retain failing evidence when a correction depends on it. Agent contributors must also follow [AGENTS.md](AGENTS.md), including the GPT-6 Astra model policy and isolated ownership.

## Original work and a respectful space

Production art and audio are created for NULLSPACE. Do not submit copied franchise content, ripped models, downloaded game-content packs, or assets with unclear provenance. Retain editable sources, generation/export steps and any applicable license information. Disclose AI-assisted work and describe how you inspected it.

Keep feedback specific and respectful. Critique the work, explain the problem and give the maintainer enough context to act.
