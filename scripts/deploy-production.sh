#!/usr/bin/env bash
set -euo pipefail

compose() {
  docker compose --env-file .env.production -f compose.production.yaml "$@"
}

compose config --quiet
compose build api
compose up -d --wait db
compose run --rm --no-deps api npm run migrate
compose up -d --wait --no-build api
compose exec -T api node -e '
  fetch("http://127.0.0.1:3000/products?limit=1").then(response => {
    if (!response.ok) process.exitCode = 1;
  }).catch(() => { process.exitCode = 1; });
'
