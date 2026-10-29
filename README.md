# Dashwise website (getdashwise.nl)

Plain static HTML and CSS. No build step, no JavaScript, no external requests. The HTML files are the
source.

| File | Purpose |
|---|---|
| `index.html`, `support.html`, `privacy.html` | English pages (landing, App Store Support URL, App Store Privacy URL) |
| `nl/index.html`, `nl/support.html`, `nl/privacy.html` | Dutch versions (`hreflang` pairs with the English pages) |
| `404.html` | Bilingual not-found page (Cloudflare Pages serves it automatically) |
| `assets/style.css`, `assets/mark.svg` | Shared styles (tokens from the app's Race and Day themes), vector app mark |
| `favicon.ico`, `favicon-16.png`, `favicon-32.png`, `apple-touch-icon.png`, `icon-192.png`, `icon-512.png`, `assets/app-icon-1024.png` | Icon set, generated from the app's `AppIcon-1024.png` with `sips` |
| `og-image.png` | 1200x630 social card (Open Graph, Twitter) |
| `site.webmanifest` | Web manifest (name, theme colour `#111418`, icons) |
| `robots.txt`, `sitemap.xml`, `llms.txt` | Crawl files for search engines and AI assistants |
| `_headers` | Cloudflare Pages response headers: strict CSP, cache rules, content types, `noindex` for `README.md` |

URLs are clean (`/support`, not `/support.html`): Cloudflare Pages redirects `.html` to the clean URL, so
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

## Deploy on Cloudflare Pages

1. Cloudflare dashboard > Workers & Pages > Create > Pages > Connect to Git, pick this repository.
2. Framework preset: None. Build command: empty. **Build output directory: `/` (the repo root)**.
3. Deploy. Check the preview URL, then open Custom domains > Set up a custom domain > `getdashwise.nl`
   (and `www.getdashwise.nl`, redirecting to the apex). The domain's DNS must be on Cloudflare.
4. Check the headers with `curl -sI https://getdashwise.nl/` and a CSP check in the browser console.

## After deploying: get found

1. Deploy, then check `https://getdashwise.nl/robots.txt`, `/sitemap.xml`, `/llms.txt`, `/site.webmanifest` and `curl -sI https://getdashwise.nl/README.md` (expect `x-robots-tag: noindex`).
2. **Google Search Console:** add a Domain property, verify with the DNS TXT record (Cloudflare DNS > Add record > TXT), then Sitemaps > submit `https://getdashwise.nl/sitemap.xml`. Request indexing for `/` and `/nl/`.
3. **Bing Webmaster Tools:** add the site (import from Search Console, or verify with a DNS TXT/CNAME record in Cloudflare) and submit the same sitemap. Bing feeds Copilot and other AI assistants.
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
