#!/usr/bin/env bash
set -euo pipefail

: "${BASE_URL:?Set BASE_URL to the site origin, without trailing slash}"

routes_file=${ROUTES_FILE:-"$(dirname "$0")/routes.txt"}
connect_timeout=${CURL_CONNECT_TIMEOUT:-5}
max_time=${CURL_MAX_TIME:-20}
response_root=$(mktemp -d "${TMPDIR:-/tmp}/contra-http-responses.XXXXXX")
chmod 700 "$response_root"
trap 'rm -rf -- "$response_root"' EXIT

line_number=0

while IFS=$'\t' read -r label route expected_status marker extra; do
  line_number=$((line_number + 1))

  case "$label" in
    ''|'#'*) continue ;;
  esac

  if [ -z "$route" ] || [ -z "$expected_status" ] || [ -z "$marker" ] || [ -n "$extra" ]; then
    printf 'Invalid smoke route at line %d\n' "$line_number" >&2
    exit 1
  fi

  body="$response_root/$line_number.body"
  error_log="$response_root/$line_number.error"

  if ! result=$(curl \
    --silent \
    --show-error \
    --location \
    --compressed \
    --connect-timeout "$connect_timeout" \
    --max-time "$max_time" \
    --output "$body" \
    --write-out $'%{http_code}\t%{num_redirects}' \
    "${BASE_URL%/}${route}" \
    2> "$error_log"); then
    printf 'Smoke request failed: %s %s\n' "$label" "$route" >&2
    exit 1
  fi

  IFS=$'\t' read -r status redirects <<< "$result"

  if [ "$status" != "$expected_status" ]; then
    printf 'Unexpected final status for %s %s: expected %s, got %s\n' \
      "$label" "$route" "$expected_status" "$status" >&2
    exit 1
  fi

  if ! grep -Fq -- "$marker" "$body"; then
    printf 'Content marker missing for %s %s\n' "$label" "$route" >&2
    exit 1
  fi

  printf '%s %s %s redirects=%s marker=ok\n' "$status" "$label" "$route" "$redirects"
done < "$routes_file"
