# Website descent redesign — 2026-09-07

Scope: `site/` and focused website verification. Existing game source, dependencies, release binaries, GitHub Pages publishing path and custom domain configuration are unchanged. The additional website check runs with Node's standard library; production remains buildless.

## Executed checks

- Existing repository-checks Python gate: **PASS**, 2 HTML pages, all local asset and fragment targets, stylesheet URLs, `/NULLSPACE/` path containment.
- `node --check site/script.js`: **PASS**.
- `node tools/check-site-interactions.mjs`: **PASS**. Actual script executed with a minimal DOM double: no Audio object on load; user-activated playback; hum silenced at blackout; silhouette before cranial reveal; system reduced-motion default and live change; manual motion control; directory End-key selection; dialog focus return; hidden-tab playback pause; no continuous requestAnimationFrame loop. This is source-level verification, not a browser test.
- SHA-256 comparisons: added corridor and hum are byte-for-byte copies of the original project assets named in provenance.
- GitHub release API: v0.1 is an existing prerelease, with Windows ZIP (95,405,907 bytes), Linux TAR.GZ (85,489,317 bytes) and SHA256SUMS.txt. No download or gameplay test was performed by this website change.
- Font advance checks used the actual self-hosted font. The mobile wordmark is within the available 320px viewport width at its normal text size. This does not establish complete layout acceptance.

## Visual acceptance remains open

The supervised preview started successfully. Its first browser navigation was rejected because permission was declined. No browser screenshots were captured; no alternate browser, raw automation or indirect screenshot mechanism was used. Preview was stopped and its temporary server harness removed.

Desktop/mobile screenshot review, real-browser interaction checks, native mobile performance and actual audio listening remain **unverified**. Do not describe this redesign as visually accepted. A follow-up should capture arrival, the office transition, silhouette, complete Listener reveal and the download at desktop, narrow mobile and reduced-motion settings, then correct observed defects.

## Publication

User explicitly requested GitHub Pages only. The existing GitHub Pages workflow remains the publishing mechanism; no OpenAI Site was registered or deployed.
