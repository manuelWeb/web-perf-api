#!/usr/bin/env bash
set -euo pipefail

# Isolate the containers and volume from any developer database.
project="web-perf-api-test-$$"
export POSTGRES_VOLUME="$project"
export PGPASSWORD=smoke-test-only DD_VERSION=smoke-test DD_TRACE_ENABLED=false
export API_HOST_PORT="${SMOKE_TEST_PORT:-31987}"

compose() {
  docker compose --env-file .env.production.example -p "$project" -f compose.production.yaml "$@"
}

docker volume create "$POSTGRES_VOLUME" >/dev/null
backup=$(mktemp)
cleanup() {
  rm -f "$backup"
  compose down
  docker volume rm "$POSTGRES_VOLUME" >/dev/null
}
trap cleanup EXIT

compose build api
compose up -d --wait db
compose run --rm --no-deps api npm run migrate
compose run --rm --no-deps api npm run migrate
compose run --rm --no-deps -e NODE_ENV=development api npm run seed:dev
compose up -d --wait --no-build api

base="http://127.0.0.1:$API_HOST_PORT"
curl -fsS "$base/health" | node -e 'if (JSON.parse(require("node:fs").readFileSync(0)).status !== "ok") process.exit(1)'
test "$(curl -s -o /dev/null -w '%{http_code}' "$base/products?limit=0")" = 400
test "$(curl -s -o /dev/null -w '%{http_code}' "$base/products/2147483647")" = 404
test "$(curl -s -o /dev/null -w '%{http_code}' "$base/apm-demo/error")" = 404
test -z "$(docker port "$(compose ps -q db)")"

curl -fsS -D - -o /dev/null -X OPTIONS \
  -H 'Origin: https://webperfs.webdesignord.fr' \
  -H 'Access-Control-Request-Method: GET' \
  -H 'Access-Control-Request-Headers: traceparent,tracestate' "$base/products" |
  tr -d '\r' |
  awk 'tolower($0) == "access-control-allow-origin: https://webperfs.webdesignord.fr" { origin = 1 }
       tolower($0) == "access-control-allow-headers: traceparent,tracestate" { headers = 1 }
       END { exit !(origin && headers) }'

compose exec -T db sh -c 'pg_dump -Fc -U "$POSTGRES_USER" -d "$POSTGRES_DB"' > "$backup"
compose exec -T db sh -c 'createdb -U "$POSTGRES_USER" web_perf_restore'
compose exec -T db sh -c 'pg_restore --exit-on-error -U "$POSTGRES_USER" -d web_perf_restore' < "$backup"
test "$(compose exec -T db sh -c 'psql -At -U "$POSTGRES_USER" -d web_perf_restore -c "SELECT count(*) FROM products"')" = 2

compose down --volumes
compose up -d --wait --no-build
curl -fsS "$base/products" | node -e '
  const products = JSON.parse(require("node:fs").readFileSync(0))
  if (products.length !== 2 || products[0].sku !== "demo-notebook") process.exit(1)
'
