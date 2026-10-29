# Dashwise website (getdashwise.nl)

Plain static HTML and CSS in `public/`, served by unprivileged nginx in Docker. No build step, no
JavaScript, no external requests. A push to `main` deploys automatically through a self-hosted GitHub
runner on the web server.

| File | Purpose |
|---|---|
| `public/index.html`, `support.html`, `privacy.html` | English pages (landing, App Store Support URL, App Store Privacy URL) |
| `public/nl/index.html`, `nl/support.html`, `nl/privacy.html` | Dutch versions (`hreflang` pairs with the English pages) |
| `public/404.html` | Bilingual not-found page |
| `assets/style.css`, `assets/mark.svg` | Shared styles (tokens from the app's Race and Day themes), vector app mark |
| `favicon.ico`, `favicon-16.png`, `favicon-32.png`, `apple-touch-icon.png`, `icon-192.png`, `icon-512.png`, `assets/app-icon-1024.png` | Icon set, generated from the app's `AppIcon-1024.png` with `sips` |
| `og-image.png` | 1200x630 social card (Open Graph, Twitter) |
| `site.webmanifest` | Web manifest (name, theme colour `#111418`, icons) |
| `robots.txt`, `sitemap.xml`, `llms.txt` | Crawl files for search engines and AI assistants |
| `Dockerfile`, `compose.yaml`, `docker/` | nginx image, container settings, server config (clean URLs, 404, cache) and the security headers (strict CSP) |
| `.github/workflows/deploy.yml` | Build and restart the container on every push to `main`, then smoke-test it |

URLs are clean (`/support`, not `/support.html`): nginx serves `/support` from `support.html` and redirects `/support.html` to `/support`, so
canonicals, hreflang and the sitemap use the clean form. The JSON-LD blocks are data blocks, so the
`script-src 'none'` CSP does not affect them. Keep the FAQ JSON-LD on the support pages identical to the
visible FAQ when you edit either.

## To do before going live

- Replace the two `TODO: App Store URL` links in `index.html` and in `nl/index.html`; also add `downloadUrl` to the JSON-LD.
- Confirm the price (`TODO` comment above the JSON-LD in both index pages, now `0 EUR`) once Pricing and Availability is set.
- Set the date on `privacy.html` and `nl/privacy.html` ("Last updated") to the publication date and remove the TODO comments.
- Put real screenshots at the `<!-- SCREENSHOT: ... -->` slots. Images must be served from this site
  (CSP: `img-src 'self'`).
- Android: when the app ships, add the class `is-on` to `<section class="platform-android">`.

## Run locally

```bash
docker compose up -d --build
```

The site is then on http://127.0.0.1:8080 (set `WEB_PORT` for another port).

## Deploy: Docker on your server with a self-hosted runner

One-time setup on the server (Linux with Docker and the Compose plugin):

1. **Runner user:** create a user for the runner and add it to the `docker` group:
   `sudo useradd -m -s /bin/bash gh-runner && sudo usermod -aG docker gh-runner`.
2. **Runner:** on GitHub, open this repo > Settings > Actions > Runners > New self-hosted runner > Linux, and
   follow the commands as `gh-runner`. At `config.sh`, add the label `dashwise-website`
   (`--labels dashwise-website`). Then install it as a service: `sudo ./svc.sh install gh-runner && sudo ./svc.sh start`.
3. **Reverse proxy and TLS:** the container listens only on `127.0.0.1:8080`. Point `getdashwise.nl` and
   `www.getdashwise.nl` (redirect to the apex) at it from your reverse proxy, for example with Caddy:

   ```
   getdashwise.nl {
       reverse_proxy 127.0.0.1:8080
   }
   www.getdashwise.nl {
       redir https://getdashwise.nl{uri} permanent
   }
   ```

   DNS: an A/AAAA record for `getdashwise.nl` and `www` pointing at the server.
4. **First deploy:** Actions > Deploy > Run workflow, or push to `main`. The workflow builds the image,
   restarts the container, checks `/healthz`, `/`, `/nl/`, `/support` and the 404, and prunes old images.

Keep this repository **private** while it uses a self-hosted runner: the workflow only runs on pushes to
`main`, but a public repo would let anyone's pull request target your server's runner.

Check the live headers with `curl -sI https://getdashwise.nl/`.

## After deploying: get found

1. Deploy, then check `https://getdashwise.nl/robots.txt`, `/sitemap.xml`, `/llms.txt` and `/site.webmanifest`.
2. **Google Search Console:** add a Domain property, verify with the DNS TXT record (at your DNS provider), then Sitemaps > submit `https://getdashwise.nl/sitemap.xml`. Request indexing for `/` and `/nl/`.
3. **Bing Webmaster Tools:** add the site (import from Search Console, or verify with a DNS TXT/CNAME record) and submit the same sitemap. Bing feeds Copilot and other AI assistants.
4. Fill in the App Store link and the price TODOs (see above), then re-check the pages in the Rich Results Test (`search.google.com/test/rich-results`) and the social card in a share preview.
5. After the app is live, add the App Store link to `sameAs`/`downloadUrl` in the JSON-LD and to `llms.txt`.

`_preview/` (local screenshots) is git-ignored.

## info@getdashwise.nl with Cloudflare Email Routing

1. Cloudflare dashboard > the `getdashwise.nl` zone > Email > Email Routing > Get started.
2. Add the custom address `info` with destination your own mailbox. Confirm the verification e-mail
   sent to that mailbox.
3. Let Cloudflare add the MX and SPF records when it asks.
4. Send a test mail to info@getdashwise.nl. Email Routing only forwards. To reply as info@, add it as a
   "send as" address in your mail client through an SMTP service, and add that service to the SPF record.
