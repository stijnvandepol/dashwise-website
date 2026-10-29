# Static site for getdashwise.nl, served by unprivileged nginx on port 8080.
FROM nginxinc/nginx-unprivileged:1.27-alpine

COPY docker/nginx.conf /etc/nginx/conf.d/default.conf
COPY docker/security-headers.conf /etc/nginx/snippets/security-headers.conf
COPY public/ /usr/share/nginx/html/

# Version the stylesheet link with the commit, so browsers and Cloudflare never mix new pages with an
# old style.css.
ARG ASSET_VERSION=dev
USER root
RUN find /usr/share/nginx/html -name '*.html' -exec sed -i "s#/assets/style.css\"#/assets/style.css?v=${ASSET_VERSION}\"#g" {} +
USER 101

EXPOSE 8080
HEALTHCHECK --interval=30s --timeout=3s --retries=3 \
  CMD wget -q -O /dev/null http://127.0.0.1:8080/healthz || exit 1
