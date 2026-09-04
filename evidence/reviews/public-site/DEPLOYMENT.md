# Public website deployment

2026-09-05 (Europe/Berlin). User explicitly authorized a public GitHub repository and GitHub Pages website. No game release or gameplay acceptance is implied.

- Published source: `3a4fb26cf6fd011604a2bf2db7d2ee8f13490186`.
- Successful workflow: https://github.com/marius4lui/NULLSPACE/actions/runs/33926965390 (checks, package, deployment all passed).
- Live site: https://github.marius4lui.dev/NULLSPACE/ . The standard github.io project URL redirects to the account's existing custom domain. HTTPS enforced; no unrelated domain configuration changed.
- Root HTTPS smoke: index, CSS, JavaScript, three WebP images, favicon, sitemap and explicit 404 page returned 200 and matched local source bytes by SHA-256. A nonexistent page returned 404 with the custom NULLSPACE response.
- Independent local browser review: 41/41 checks passed, recorded alongside this document. Root opened desktop hero/world and mobile hero/Listener screenshots. These are website checks, not game playthrough evidence.
- Repository: public; homepage/topics, Issues, Discussions, contributor guide, issue/PR templates and private vulnerability reporting configured. No software or asset reuse license was granted.
- GitHub emitted non-failing Node 20 action-runtime deprecation notices for pinned official Pages actions; runner used Node 24 and all jobs succeeded.

Only the static `site/` directory is deployed. Unaccepted gameplay branches were not integrated by this task. The website accurately states that no public playable campaign is available.
