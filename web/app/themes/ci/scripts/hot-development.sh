#!/usr/bin/env bash
set -euo pipefail

theme_dir=$(cd "$(dirname "$0")/.." && pwd)
readonly development_host='contraindicaciones.test'
readonly node_image='node:14.21.3-bullseye@sha256:9b60cdcee9c6a27227689ebf4e7dd422ff195e978ffec360db5c0b3a05e20452'
hmr_port=${HMR_PORT:-8081}
browsersync_port=${BROWSERSYNC_PORT:-3000}

fail() {
  printf '%s\n' "$1" >&2
  exit 1
}

validate_port() {
  local name=$1
  local value=$2

  if [[ ! "$value" =~ ^[0-9]{4,5}$ ]] || (( 10#$value < 1024 || 10#$value > 65535 )); then
    fail "$name must be an integer between 1024 and 65535"
  fi
}

is_ipv4() {
  local ip=$1
  local octet
  local -a octets

  IFS=. read -r -a octets <<< "$ip"
  [ "${#octets[@]}" -eq 4 ] || return 1

  for octet in "${octets[@]}"; do
    [[ "$octet" =~ ^[0-9]{1,3}$ ]] || return 1
    (( 10#$octet <= 255 )) || return 1
  done
}

assert_port_is_free() {
  local port=$1

  if lsof -nP -iTCP:"$port" -sTCP:LISTEN >/dev/null 2>&1; then
    fail "Port $port is already in use"
  fi
}

assert_lsof_is_available() {
  command -v lsof >/dev/null 2>&1 || fail 'lsof is required to check HMR and BrowserSync ports'
}

resolve_host_ipv4() {
  local ip

  if ip=$(getent ahostsv4 "$development_host" 2>/dev/null | awk 'NR == 1 { print $1 }'); then
    if is_ipv4 "$ip"; then
      printf '%s\n' "$ip"
      return 0
    fi
  fi

  if command -v dscacheutil >/dev/null 2>&1; then
    dscacheutil -q host -a name "$development_host" | awk '$1 == "ip_address:" { print $2; exit }'
    return
  fi

  return 1
}

validate_port HMR_PORT "$hmr_port"
validate_port BROWSERSYNC_PORT "$browsersync_port"
[ "$hmr_port" != "$browsersync_port" ] || fail 'HMR_PORT and BROWSERSYNC_PORT must be different'

if ! host_ip=$(resolve_host_ipv4); then
  fail "Unable to resolve $development_host"
fi

is_ipv4 "$host_ip" || fail "Unable to resolve $development_host to an IPv4 address"
assert_lsof_is_available
assert_port_is_free "$hmr_port"
assert_port_is_free "$browsersync_port"

docker run --rm --platform linux/amd64 \
  --user "$(id -u):$(id -g)" \
  --env HOME=/tmp \
  --env YARN_CACHE_FOLDER=/tmp/yarn-cache \
  --env "BROWSERSYNC_PORT=$browsersync_port" \
  --publish "127.0.0.1:${hmr_port}:${hmr_port}" \
  --publish "127.0.0.1:${browsersync_port}:${browsersync_port}" \
  --add-host "${development_host}:${host_ip}" \
  --volume "$theme_dir:/app" \
  --workdir /app \
  "$node_image" \
  bash -lc "yarn install --frozen-lockfile && yarn build && yarn mix:hot --host 0.0.0.0 --port $hmr_port --hmr-port $hmr_port"
