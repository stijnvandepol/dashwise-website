# getdashwise.nl

The website for **Dashwise**, the iPhone app that turns an ELM327 OBD-II adapter into a live
dashboard, fault-code reader and trip logbook. An Android version will follow.

- **Stack:** plain static HTML and CSS, served by unprivileged nginx in Docker.
- **Privacy:** no build step, no JavaScript, no cookies, no analytics, no external requests.
- **Deploy:** every push to `main` deploys automatically through a self-hosted GitHub runner on the
  web server.

## Contents

- [Repository layout](#repository-layout)
- [Run locally](#run-locally)
- [Deployment](#deployment)
- [Editing the site](#editing-the-site)
- [Security](#security)
- [Launch checklist](#launch-checklist)
- [E-mail: info@getdashwise.nl](#e-mail-infogetdashwisenl)

## Repository layout

```
public/                     Everything the site serves (the container's web root)
  index.html                English landing page
  support.html              Support and FAQ (App Store Support URL)
  privacy.html              Privacy policy (App Store Privacy Policy URL)
  404.html                  Bilingual not-found page
  nl/                       Dutch versions of the three pages
  .well-known/security.txt  RFC 9116 security contact (renew Expires yearly)
  assets/style.css          All styles; colour tokens from the app's Race (dark) and Day (light) themes
  assets/mark.svg           Vector app mark used in the header
  assets/app-icon-1024.png  The app icon (source for the icon set)
  favicon*.ico|png, apple-touch-icon.png, icon-192.png, icon-512.png
  og-image.png              1200x630 social card (Open Graph, X, WhatsApp, LinkedIn)
  site.webmanifest          Web app manifest
  robots.txt, sitemap.xml   Crawl files for search engines
  llms.txt                  Plain-text summary for AI assistants
docker/
  nginx.conf                Server config: clean URLs, 404, caching, /healthz
  security-headers.conf     CSP and other security headers, included in every location
Dockerfile                  nginx-unprivileged image with the config and public/
compose.yaml                Container settings (localhost only, read-only, no capabilities)
.github/workflows/deploy.yml  Build, restart and smoke-test on every push to main
```

`_preview/` holds local screenshots and is git-ignored.

## Run locally

```bash
docker compose up -d --build
```

Open http://127.0.0.1:8080. To use another port, set `WEB_PORT`, for example
`WEB_PORT=9000 docker compose up -d --build`. Stop the site with `docker compose down`.

To preview the HTML without Docker, run `python3 -m http.server -d public 8000`. Clean URLs such as
`/support` only work through nginx; use `/support.html` there.

## Deployment

### How it works

On every push to `main`, and on demand through Actions > Deploy > Run workflow, the runner on the
server:

1. checks out the repository;
2. builds the image (`docker compose build --pull`);
3. replaces the running container (`docker compose up -d --remove-orphans`);
4. checks `/healthz`, `/`, `/nl/` and `/support`, and that a missing page returns 404;
5. removes old images.

If a check fails, the run turns red in the Actions tab. The new container is then already running, so
fix the problem or roll back (see below).

The container listens only on `127.0.0.1:8080`. A reverse proxy on the same server terminates HTTPS
for `getdashwise.nl`.

### One-time server setup

You need a Linux server with Docker, the Docker Compose plugin and a reverse proxy.

1. **Create a runner user** that may use Docker:

   ```bash
   sudo useradd -m -s /bin/bash gh-runner
   sudo usermod -aG docker gh-runner
   ```

2. **Install the runner.** On GitHub, open this repository > Settings > Actions > Runners >
   New self-hosted runner > Linux, and run the commands it shows as `gh-runner`
   (`sudo -iu gh-runner`). When `config.sh` asks for labels, add `dashwise-website`, or pass
   `--labels dashwise-website`. Then, from the runner folder, install it as a service:

   ```bash
   sudo ./svc.sh install gh-runner
   sudo ./svc.sh start
   ```

   The runner must show as **Idle** under Settings > Actions > Runners.

3. **DNS:** add A (and AAAA) records for `getdashwise.nl` and `www.getdashwise.nl` that point at the
   server.

4. **Reverse proxy:** forward the domain to the container and redirect `www` to the apex. With Caddy
   (HTTPS certificates are automatic):

   ```
   getdashwise.nl {
       reverse_proxy 127.0.0.1:8080
   }

   www.getdashwise.nl {
       redir https://getdashwise.nl{uri} permanent
   }
   ```

   Caddy writes no access log unless you add a `log` directive; keep it that way, because the privacy
   page promises logs without IP addresses. With nginx or Traefik, turn the access log off for this
   site or use a format without the client address.

   With nginx or Traefik, proxy to `http://127.0.0.1:8080`, keep the `Host` header, and let the proxy
   handle the certificates.

5. **First deploy:** Actions > Deploy > Run workflow. Then check:

   ```bash
   curl -sI https://getdashwise.nl/ | grep -i content-security-policy
   curl -sI https://getdashwise.nl/support.html | grep -i location   # expect /support
   ```

### Rolling back

Revert the bad commit and push. The runner deploys the previous state:

```bash
git revert <commit>
git push
```

### Troubleshooting

| Symptom | Check |
|---|---|
| The run stays "Queued" | The runner is offline: `sudo ./svc.sh status` in the runner folder, or Settings > Actions > Runners. Check that the label is `dashwise-website`. |
| `permission denied ... docker.sock` | `gh-runner` is not in the `docker` group. Add it, then restart the runner service. |
| `port is already allocated` | Something else uses 8080. Set `WEB_PORT` for the runner, for example in the runner's `.env`, and point the proxy at that port. |
| The site is up but shows an old version | Check that the last Deploy run is green, and clear the proxy's or the CDN's cache if you use one. |
| Container logs | `docker logs dashwise-website` |

## Editing the site

- **Pages** are hand-written HTML in `public/`. Edit the English and the Dutch page together.
- **Styles** live only in `public/assets/style.css`. Inline `style` attributes and `<script>` blocks are
  blocked by the CSP, so they would not work.
- **Images** must come from this site (`img-src 'self'`). Put them in `public/assets/`, give them
  `width`, `height` and `alt`, and keep them small. Real screenshots go at the
  `<!-- SCREENSHOT: ... -->` slots.
- **Links** use clean URLs (`/support`, `/nl/privacy`). nginx serves `support.html` for `/support` and
  redirects `/support.html` to `/support`, so canonicals, `hreflang` and the sitemap all use the clean
  form.
- **FAQ:** the FAQ JSON-LD on the support pages must stay identical to the visible FAQ. Change both.
  JSON-LD is a data block, not a script, so the CSP does not block it.
- **A new page:**
  1. add the English and the Dutch file;
  2. add `canonical` and `hreflang` (en, nl, x-default) in both;
  3. add both URLs to `sitemap.xml`;
  4. link the page from the header or footer.
- **Android:** when the app ships, add the class `is-on` to `<section class="platform-android">` on both
  index pages, and add the Play Store link.

## Security

Every response gets these headers (`docker/security-headers.conf`):

- a strict Content Security Policy: only this site's own files, no scripts, no frames;
- `Referrer-Policy: no-referrer`;
- `X-Content-Type-Options: nosniff`;
- `Permissions-Policy` that turns off camera, location, sensors and the like;
- HSTS.

The container runs nginx as a non-root user, with a read-only file system, no Linux capabilities and
`no-new-privileges`. It only listens on localhost.

**Keep this repository private.** It uses a self-hosted runner. In a public repository, someone's pull
request could run code on your server.

## Launch checklist

**Before going live**

- [ ] Replace the `TODO: App Store URL` links in `public/index.html` and `public/nl/index.html`, and add
      `downloadUrl` to their JSON-LD.
- [ ] Confirm the price in the JSON-LD (now `0 EUR`, with a `TODO` comment) once it is set in
      App Store Connect.
- [ ] Set "Last updated" on both privacy pages to the publication date, and remove the TODO comments.
- [ ] Fill in the imprint placeholders (visible as `[address]`, `[KvK]`, `[btw-id]`, each with a `TODO`
      comment) in the footer of all six pages, and in `privacy.html` and `nl/privacy.html`
      (address, KvK number). The btw-id is the VAT id, not the BSN-based number.
- [ ] Fill in `[mail provider]` in both privacy pages (`TODO: mail provider`).
- [ ] TODO: log rotation. The privacy pages promise logs are kept at most 14 days and nginx logs to
      stdout/stderr, so set the Docker log driver on the server, for example in `compose.yaml`:
      `logging: {driver: json-file, options: {max-size: "10m", max-file: "3"}}`, and check that the log
      size and rotation stay within 14 days. The access log has no IP addresses, but the reverse proxy
      on the host has its own logs: configure those without IP addresses too, or adjust the privacy text.
- [ ] Switch the security contact to security@getdashwise.nl when that address exists (`security.txt`,
      both support pages, both privacy pages).
- [ ] Add real screenshots at the screenshot slots.
- [ ] Update `lastmod` in `sitemap.xml` when pages change.

**Every year**

- [ ] Renew `Expires` in `public/.well-known/security.txt` (now 2027-10-29) before it passes. RFC 9116
      requires it.

**After going live: get found**

1. Check `https://getdashwise.nl/robots.txt`, `/sitemap.xml`, `/llms.txt` and `/site.webmanifest`.
2. **Google Search Console:** add a Domain property and verify it with the DNS TXT record. Submit
   `https://getdashwise.nl/sitemap.xml`, then request indexing for `/` and `/nl/`.
3. **Bing Webmaster Tools:** import the site from Search Console, or verify it with DNS. Submit the same
   sitemap. Bing also feeds Copilot and other AI assistants.
4. Test the index pages in the [Rich Results Test](https://search.google.com/test/rich-results), and the
   social card with a share preview in WhatsApp or LinkedIn.
5. Once the app is in the App Store, add its link to `sameAs` and `downloadUrl` in the JSON-LD, and to
   `llms.txt`.

## E-mail: info@getdashwise.nl

The site only shows the address; it does not handle mail. One way to receive it, if the domain's DNS is
on Cloudflare, is Email Routing:

1. Cloudflare dashboard > the `getdashwise.nl` zone > Email > Email Routing > Get started.
2. Add the address `info` and forward it to your own mailbox. Confirm the verification e-mail.
3. Let Cloudflare add the MX and SPF records.
4. Send a test mail. To reply *as* info@getdashwise.nl, add it as a "send as" address in your mail
   client through an SMTP service, and add that service to the SPF record.

Any mail host works instead: point the MX records at it.
