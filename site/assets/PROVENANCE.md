# NULLSPACE website imagery

These are original NULLSPACE project assets, not stock art or finished gameplay screenshots. Existing WebP files are full-dimension format conversions of the source PNGs (Pillow, WebP quality 88, method 6); no visual content was added or removed. Original editable Blender sources and generation scripts are retained in the repository and art development branches.

| Website file | Original source | Context |
| --- | --- | --- |
| `environment.webp` | `docs/images/environment-preview.png` | Original Blender environment source render, early room candidate. |
| `listener.webp` | `tools/art/listener/evidence/source_body_03.png` in `agent/monster-art` | Original Listener full-body Blender render, revision 03. |
| `listener-detail.webp` | `tools/art/listener/evidence/source_head_03.png` in `agent/monster-art` | Original Listener cranial Blender render, revision 03. |
| `favicon.svg` | `site/assets/favicon.svg` | Original geometric N mark authored for the public website. |
| `corridor.png` | `branding/v1/nullspace-banner.png` | Byte-for-byte copy of existing original illustrative key art, generated at the user's request on 2026-09-05. CSS frames the corridor above its embedded logo. Not a gameplay image. Prompts and provenance: `branding/v1/README.md`. |
| `audio/hum.wav` | `game/assets/audio/room/hum_1.wav` | Byte-for-byte copy of original seeded room-hum synthesis. Recipe and metrics: `art/source/audio/room/synthesis.json`. Activated only by the sound button; no new recording or game-audio quality claim. |

## Website typography

`fonts/barlow-condensed-black.woff` is Barlow Condensed Black by Jeremy Tribby, obtained from the [Google Fonts source repository](https://github.com/google/fonts/blob/main/ofl/barlowcondensed/BarlowCondensed-Black.ttf) on 2026-09-05. The original TTF was converted to WOFF with fontTools without changing glyphs. It is self-hosted; the full SIL Open Font License 1.1 and copyright notice are retained in [`fonts/OFL.txt`](fonts/OFL.txt). All other text uses system fonts.

The website redesign reuses the three existing render files unchanged and the existing corridor key art. CSS crops, masks, blends and tonal treatments are presentation only; the image viewer opens the unmodified render assets. The building directory describes the story route, not a literal floor plan. No new image generation or invented gameplay footage was used.

Creator of original project imagery: GPT-6 Astra through Codex, under the direction of marius4lui. Development imagery is subject to further art review. Asset publication does not indicate gameplay integration or quality-gate acceptance. No reuse license has been granted for that imagery; public availability alone does not grant reuse rights. The separately attributed font uses the license above.
