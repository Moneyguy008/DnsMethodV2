# Private DNS Guide (macOS)

A small static website with step-by-step instructions for setting up
**encrypted DNS (DNS-over-HTTPS)** on a Mac, plus a troubleshooting page
for common problems. No build step — plain HTML/CSS/JS.

## Pages
- `index.html` — overview + "will this help me?"
- `mac.html` — the setup guide (easy profile + advanced dnscrypt-proxy)
- `troubleshooting.html` — common problems and fixes
- `assets/` — stylesheet, script, and downloadable files

## Host it free on GitHub Pages

1. Create a new repository on GitHub (e.g. `private-dns-guide`).
2. Put these files in the repo root and push:
   ```bash
   cd private-dns-site
   git init
   git add .
   git commit -m "Private DNS guide"
   git branch -M main
   git remote add origin https://github.com/YOUR-USERNAME/private-dns-guide.git
   git push -u origin main
   ```
3. On GitHub: **Settings → Pages → Build and deployment**.
   Set **Source: Deploy from a branch**, **Branch: `main`**, folder **`/ (root)`**, Save.
4. Wait ~1 minute. Your site is live at:
   `https://YOUR-USERNAME.github.io/private-dns-guide/`

To use a custom domain later, add it under Settings → Pages → Custom domain.

## Editing
Everything is plain HTML. Change the text directly in the `.html` files.
Colors and layout live in `assets/style.css`.

## Note
Provided as-is. Intended for networks you're permitted to configure
(home Wi-Fi, personal hotspot). Changing DNS on school/work networks may
violate their policies.
