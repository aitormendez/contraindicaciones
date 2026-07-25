#!/usr/bin/env bash
set -euo pipefail

: "${BASE_URL:?Set BASE_URL to the site origin, without trailing slash}"

while IFS= read -r route; do
  [ -n "$route" ] || continue
  status=$(curl --silent --show-error --location --output /dev/null \
    --write-out '%{http_code}' "${BASE_URL}${route}")
  case "$route" in
    /wp/wp-login.php) [ "$status" = "200" ] || [ "$status" = "302" ] ;;
    *) [ "$status" = "200" ] ;;
  esac
  printf '%s %s\n' "$status" "$route"
done < "$(dirname "$0")/routes.txt"
