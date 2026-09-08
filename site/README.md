# NULLSPACE public website

Dependency-free HTML, CSS and JavaScript, published from `site/` by the existing GitHub Pages workflow. No build step, package installation, external scripts, analytics, or OpenAI hosting. Relative assets preserve the `/NULLSPACE/` project path and the inherited account domain `https://github.marius4lui.dev/NULLSPACE/`. Do not add a project CNAME.

## Local preview

From the repository root: `python3 -m http.server 4173 --directory site`. To exercise the project base and custom 404, also test with `/NULLSPACE/` mapped to `site/`.

## Experience

- Native scrolling drives two sticky sequences: illustrative corridor → original office render → blackout, then a faint full-body Listener → controlled cranial reveal. No scroll hijacking, ambient zoom loop, strobe, or repeated generic reveal animations.
- The browser owns scroll speed. A single scheduled animation frame updates only when scrolling, resizing, restoring or changing preferences. No permanent rendering loop.
- Sound starts only after pressing the sound control. It uses the project's original room hum, fades with the building's power and stops at blackout. Background tabs and page navigation pause playback. No microphone access or third-party audio.
- `prefers-reduced-motion` disables the sticky motion by default and follows system changes. A visible motion control provides the same static layout. Images, narrative, downloads, disclosures and source links remain available without JavaScript.
- The original image viewer supports native dialog focus containment, Escape and focus return. Unenhanced image links open the original assets.
- The compact building directory supports click, Enter/Space, arrow keys, Home and End. It is a story route, not a game map. No-JavaScript visitors have the full game-design link.
- Separate mobile typography, portrait framing, stacked downloads and static fallbacks. Direct downloads are the verified v0.1 Windows and Linux archives; release notes/checksums and platform caveats stay beside them.

## Sources and validation

See `assets/PROVENANCE.md` for original imagery and audio. The opening corridor is existing illustrative key art, not a gameplay screenshot. The other images are existing Blender studies. No new imagery or gameplay claims were generated.

The repository's existing local-reference gate covers both HTML pages, stylesheet URLs, anchors and `/NULLSPACE/` paths. Additional source-level interaction verification and the remaining visual-testing limitation are recorded in `../evidence/site-descent/VALIDATION.md`.

The site has **not** passed Desktop/Mobile screenshot review: the browser preview request was declined. Do not claim visual acceptance or native mobile testing from the source-level checks.
