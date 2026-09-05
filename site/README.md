# NULLSPACE public website

Dependency-free static website deployed from `site/` with GitHub Pages. Relative asset URLs support the `/NULLSPACE/` project path. The inherited account domain is `https://github.marius4lui.dev/NULLSPACE/`; do not add a project CNAME for that subdirectory.

## Preview

From the repository root, run `python3 -m http.server 4173 --directory site --bind 127.0.0.1`, then open `http://127.0.0.1:4173/`. No Node packages or build step are required. The custom 404 page uses `/NULLSPACE/` URLs and must be checked with that deployment path mapped to `site/`.

## Content and accessibility

- Planned mechanics and campaign targets are distinguished from current development assets.
- Four-area selector and synchronized route schematic support click, Enter/Space, arrow keys, Home and End. The diagram describes the story route, not the in-game floor plan.
- Media links work without JavaScript; enhanced lightbox supports Escape and returns focus.
- Native technical-details disclosure, visible keyboard focus, skip navigation, reduced-motion support and responsive layouts.
- Optional background motion has a pause control and follows system reduced-motion preferences. All sections are visible without JavaScript; animations start only when the pause control is available.
- No analytics, cookies, remote assets or third-party scripts. Barlow Condensed Black is self-hosted; its SIL Open Font License is included in `assets/fonts/OFL.txt`.
- See `assets/PROVENANCE.md` for original image sources. No generated gameplay imagery is used.

Update the dated current-state copy and metadata when the integrated playable state changes. Keep campaign claims consistent with `GAME_DESIGN.md`, `STATUS.md` and reviewed evidence.
