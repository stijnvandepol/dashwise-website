#!/usr/bin/env bash
# Deploy getdashwise.nl on this server: remove the old container, build and start the new one,
# check that it serves, and clean up old images. Used by the Deploy workflow; also safe to run by hand
# from a checkout of this repository (`./deploy.sh`, or `./deploy.sh --pull` to fetch main first).
set -euo pipefail

cd "$(dirname "$0")"

port="${WEB_PORT:-8080}"

if [[ "${1:-}" == "--pull" ]]; then
  echo "==> Fetching the latest main"
  git fetch --quiet origin main
  git reset --quiet --hard origin/main
fi

echo "==> Building the new image ($(git rev-parse --short HEAD))"
docker compose build --pull

echo "==> Removing the old container"
docker compose down --remove-orphans

echo "==> Starting the new container"
docker compose up -d

echo "==> Checking the site on port ${port}"
for _ in $(seq 1 15); do
  if curl -fsS "http://127.0.0.1:${port}/healthz" >/dev/null 2>&1; then break; fi
  sleep 2
done
curl -fsS -o /dev/null "http://127.0.0.1:${port}/"
curl -fsS -o /dev/null "http://127.0.0.1:${port}/nl/"
curl -fsS -o /dev/null "http://127.0.0.1:${port}/support"
test "$(curl -s -o /dev/null -w '%{http_code}' "http://127.0.0.1:${port}/does-not-exist")" = 404

echo "==> Cleaning up old images and build cache"
docker image prune -f >/dev/null
docker builder prune -f --filter "until=168h" >/dev/null

echo "==> Deployed $(git rev-parse --short HEAD), healthy on port ${port}"
