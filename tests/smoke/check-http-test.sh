#!/usr/bin/env bash
set -euo pipefail

project_dir=$(cd "$(dirname "$0")/../.." && pwd)
checker="$project_dir/tests/smoke/check-http.sh"
fixture_root=$(mktemp -d "${TMPDIR:-/tmp}/contra-http-smoke.XXXXXX")
chmod 700 "$fixture_root"
server_pid=''

cleanup() {
  if [ -n "$server_pid" ]; then
    kill "$server_pid" 2>/dev/null || true
    wait "$server_pid" 2>/dev/null || true
  fi

  rm -rf -- "$fixture_root"
}

trap cleanup EXIT

router="$fixture_root/router.php"
routes="$fixture_root/routes.tsv"

printf '%s\n' \
  '<?php' \
  '$path = parse_url($_SERVER["REQUEST_URI"], PHP_URL_PATH);' \
  'if ($path === "/redirect") {' \
  '    header("Location: /ok", true, 302);' \
  '    exit;' \
  '}' \
  'if ($path === "/slow") {' \
  '    sleep(3);' \
  '}' \
  'if ($path === "/ok" || $path === "/slow") {' \
  '    header("Content-Type: text/plain");' \
  '    echo "expected-marker";' \
  '    exit;' \
  '}' \
  'http_response_code(404);' \
  'echo "not-found";' \
  > "$router"

port=$(php -r '
  $socket = stream_socket_server("tcp://127.0.0.1:0", $errorCode, $errorMessage);
  if ($socket === false) {
      fwrite(STDERR, $errorMessage);
      exit(1);
  }
  $address = stream_socket_get_name($socket, false);
  fclose($socket);
  echo substr(strrchr($address, ":"), 1);
')

php -S "127.0.0.1:$port" "$router" > "$fixture_root/server.log" 2>&1 &
server_pid=$!

for _ in $(seq 1 50); do
  if curl --silent --fail --connect-timeout 1 --max-time 1 "http://127.0.0.1:$port/ok" > /dev/null; then
    break
  fi

  sleep 0.1
done

printf 'direct\t/ok\t200\texpected-marker\nredirect\t/redirect\t200\texpected-marker\n' > "$routes"

BASE_URL="http://127.0.0.1:$port" \
ROUTES_FILE="$routes" \
CURL_CONNECT_TIMEOUT=1 \
CURL_MAX_TIME=2 \
  "$checker" > "$fixture_root/success.log"

if ! grep -Fq '200 redirect /redirect redirects=1 marker=ok' "$fixture_root/success.log"; then
  printf 'Expected the final status and redirect count in smoke output\n' >&2
  exit 1
fi

printf 'marker\t/ok\t200\tmissing-marker\n' > "$routes"

if BASE_URL="http://127.0.0.1:$port" \
  ROUTES_FILE="$routes" \
  CURL_CONNECT_TIMEOUT=1 \
  CURL_MAX_TIME=2 \
  "$checker" > "$fixture_root/failure.log" 2>&1; then
  printf 'Expected marker mismatch to fail\n' >&2
  exit 1
fi

printf 'timeout\t/slow\t200\texpected-marker\n' > "$routes"

if BASE_URL="http://127.0.0.1:$port" \
  ROUTES_FILE="$routes" \
  CURL_CONNECT_TIMEOUT=1 \
  CURL_MAX_TIME=1 \
  "$checker" > "$fixture_root/timeout.log" 2>&1; then
  printf 'Expected slow response to time out\n' >&2
  exit 1
fi

printf 'http smoke fixtures: ok\n'
