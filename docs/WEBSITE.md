# NULLSPACE website

The public game website lives at **[github.marius4lui.dev/NULLSPACE](https://github.marius4lui.dev/NULLSPACE/)**. The standard [GitHub Pages address](https://marius4lui.github.io/NULLSPACE/) redirects through the account's existing domain configuration. No project `CNAME` file is required.

## Preview locally

From the repository root, with Python 3 installed:

```sh
python3 -m http.server 4173 --bind 127.0.0.1 --directory site
```

Open [localhost:4173](http://localhost:4173). Stop the server with `Ctrl+C`.

The site is static HTML, CSS, JavaScript and local assets in `site/`. There is no dependency installation, bundler, database or build step. Edit the source files directly. Keep local asset and page URLs relative so previews and the `/NULLSPACE/` project path both work.

## Review a change

Check navigation, buttons, keyboard focus and any interactive controls in a real browser. Inspect a narrow mobile viewport as well as desktop. Check reduced-motion behavior, readable text and image captions. Screenshots should accurately describe their source and development status; planned gameplay must remain clearly identified.

The [repository checks workflow](../.github/workflows/repository-checks.yml) checks local HTML/CSS asset references, HTML links and fragments, duplicate IDs and undeployable symlinks. It runs for pull requests, can be started manually, and is required by the Pages workflow. It does not assess visual quality, accessibility compliance or game behavior, and it does not crawl external sites.

## Publish

GitHub Pages uses **GitHub Actions** as its source. The [publish workflow](../.github/workflows/pages.yml) runs when website or workflow files change on `main`, and can also be started from the Actions tab. It validates the site, uploads **only `site/`**, and deploys through the `github-pages` environment. Other repository files and development evidence are not part of the website artifact.

Deployment permissions are limited to the deployment job; pull requests have read-only repository access. Concurrent production deployments are serialized. The workflow uses pinned official GitHub Actions and needs no custom secret or access token. A deployment can only proceed from `main`.

For workflow changes, consult [GitHub's custom Pages workflow documentation](https://docs.github.com/en/pages/getting-started-with-github-pages/using-custom-workflows-with-github-pages). The action references are pinned to official releases of [checkout](https://github.com/actions/checkout), [configure-pages](https://github.com/actions/configure-pages), [upload-pages-artifact](https://github.com/actions/upload-pages-artifact) and [deploy-pages](https://github.com/actions/deploy-pages).
