# Dashwise website (getdashwise.nl)

Plain static HTML and CSS. No build step, no JavaScript, no external requests. The HTML files are the
source.

| File | Purpose |
|---|---|
| `index.html` | Landing page |
| `support.html` | App Store Support URL |
| `privacy.html` | App Store Privacy Policy URL |
| `404.html` | Not-found page (Cloudflare Pages serves it automatically) |
| `assets/style.css`, `assets/mark.svg` | Shared styles (tokens from the app's Race and Day themes), app mark and favicon |
| `_headers` | Cloudflare Pages response headers: strict CSP, no referrer, nosniff, Permissions-Policy |

## To do before going live

- Replace the two `TODO: App Store URL` links in `index.html`.
- Set the date on `privacy.html` ("Last updated") to the publication date and remove its TODO comment.
- Put real screenshots at the `<!-- SCREENSHOT: ... -->` slots. Images must be served from this site
  (CSP: `img-src 'self'`).
- Android: when the app ships, add the class `is-on` to `<section class="platform-android">`.
- A Dutch version goes in `nl/` (copy the pages, set `lang="nl"`, link the two with `hreflang`).

## Deploy on Cloudflare Pages

1. Cloudflare dashboard > Workers & Pages > Create > Pages > Connect to Git, pick this repository.
2. Framework preset: None. Build command: empty. **Build output directory: `/` (the repo root)**.
3. Deploy. Check the preview URL, then open Custom domains > Set up a custom domain > `getdashwise.nl`
   (and `www.getdashwise.nl`, redirecting to the apex). The domain's DNS must be on Cloudflare.
4. Check the headers with `curl -sI https://getdashwise.nl/` and a CSP check in the browser console.

`_preview/` (local screenshots) is git-ignored.

## info@getdashwise.nl with Cloudflare Email Routing

1. Cloudflare dashboard > the `getdashwise.nl` zone > Email > Email Routing > Get started.
2. Add the custom address `info` with destination your own mailbox. Confirm the verification e-mail
   sent to that mailbox.
3. Let Cloudflare add the MX and SPF records when it asks.
4. Send a test mail to info@getdashwise.nl. Email Routing only forwards. To reply as info@, add it as a
   "send as" address in your mail client through an SMTP service, and add that service to the SPF record.
