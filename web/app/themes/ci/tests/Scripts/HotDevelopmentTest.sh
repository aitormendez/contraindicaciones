#!/usr/bin/env bash
set -euo pipefail

theme_dir=$(cd "$(dirname "$0")/../.." && pwd)
launcher="$theme_dir/scripts/hot-development.sh"
fixture_root=$(mktemp -d "${TMPDIR:-/tmp}/contra-hot-development.XXXXXX")
fixture_root=$(cd "$fixture_root" && pwd)
chmod 700 "$fixture_root"
trap 'rm -rf -- "$fixture_root"' EXIT

fake_bin="$fixture_root/fake bin"
fake_theme="$fixture_root/theme with spaces"
mkdir -p "$fake_bin" "$fake_theme/scripts"
ln -s "$launcher" "$fake_theme/scripts/hot-development.sh"

docker_args="$fixture_root/docker-args"
docker_calls="$fixture_root/docker-calls"
getent_args="$fixture_root/getent-args"
dscacheutil_args="$fixture_root/dscacheutil-args"

cat > "$fake_bin/docker" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
printf '%s\n' "$@" > "$DOCKER_ARGS"
printf 'called\n' >> "$DOCKER_CALLS"
EOF

cat > "$fake_bin/getent" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
printf '%s\n' "$@" > "$GETENT_ARGS"
if [ "${FAKE_UNRESOLVED:-0}" = 1 ] || [ "${FAKE_GETENT_FAIL:-0}" = 1 ]; then
  exit 2
fi
printf '%s STREAM contraindicaciones.test\n' "${FAKE_HOST_IP:-198.51.100.42}"
EOF

cat > "$fake_bin/dscacheutil" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
printf '%s\n' "$@" > "$DSCACHEUTIL_ARGS"
if [ "${FAKE_UNRESOLVED:-0}" = 1 ]; then
  exit 2
fi
printf 'name: contraindicaciones.test\nip_address: %s\n' "${FAKE_HOST_IP:-198.51.100.42}"
EOF

cat > "$fake_bin/lsof" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
case " $* " in
  *":${FAKE_OCCUPIED_PORT:-0}"*) exit 0 ;;
esac
exit 1
EOF

chmod +x "$fake_bin/docker" "$fake_bin/getent" "$fake_bin/dscacheutil" "$fake_bin/lsof"

fail() {
  printf '%s\n' "$1" >&2
  exit 1
}

assert_line() {
  local expected=$1
  local file=$2

  grep -Fqx -- "$expected" "$file" || fail "Missing Docker argument: $expected"
}

assert_pair() {
  local first=$1
  local second=$2
  local file=$3

  awk -v first="$first" -v second="$second" '
    $0 == first { getline; if ($0 == second) found = 1 }
    END { exit found ? 0 : 1 }
  ' "$file" || fail "Missing Docker argument pair: $first $second"
}

run_launcher() {
  : > "$docker_args"
  : > "$docker_calls"
  env PATH="$fake_bin:$PATH" \
    DOCKER_ARGS="$docker_args" \
    DOCKER_CALLS="$docker_calls" \
    GETENT_ARGS="$getent_args" \
    DSCACHEUTIL_ARGS="$dscacheutil_args" \
    FAKE_GETENT_FAIL="${FAKE_GETENT_FAIL:-0}" \
    HMR_PORT="${HMR_PORT:-}" \
    BROWSERSYNC_PORT="${BROWSERSYNC_PORT:-}" \
    "$fake_theme/scripts/hot-development.sh" "$@"
}

run_launcher

assert_pair '--platform' 'linux/amd64' "$docker_args"
assert_pair '--publish' '127.0.0.1:8081:8081' "$docker_args"
assert_pair '--publish' '127.0.0.1:3000:3000' "$docker_args"
assert_pair '--env' 'BROWSERSYNC_PORT=3000' "$docker_args"
assert_pair '--add-host' 'contraindicaciones.test:198.51.100.42' "$docker_args"
assert_line 'node:14.21.3-bullseye@sha256:9b60cdcee9c6a27227689ebf4e7dd422ff195e978ffec360db5c0b3a05e20452' "$docker_args"
assert_line 'yarn install --frozen-lockfile && yarn build && yarn mix:hot --host 0.0.0.0 --port 8081 --hmr-port 8081' "$docker_args"
assert_pair '--volume' "$fake_theme:/app" "$docker_args"
assert_pair 'ahostsv4' 'contraindicaciones.test' "$getent_args"

FAKE_GETENT_FAIL=1 run_launcher
assert_pair '-q' 'host' "$dscacheutil_args"
assert_pair '-a' 'name' "$dscacheutil_args"
assert_line 'contraindicaciones.test' "$dscacheutil_args"

HMR_PORT=18081 BROWSERSYNC_PORT=13000 run_launcher
assert_pair '--publish' '127.0.0.1:18081:18081' "$docker_args"
assert_pair '--publish' '127.0.0.1:13000:13000' "$docker_args"
assert_pair '--env' 'BROWSERSYNC_PORT=13000' "$docker_args"
assert_line 'yarn install --frozen-lockfile && yarn build && yarn mix:hot --host 0.0.0.0 --port 18081 --hmr-port 18081' "$docker_args"

WEBPACK_MIX="$theme_dir/webpack.mix.js" BROWSERSYNC_PORT=13000 node <<'NODE'
const Module = require('module');
const mix = {
  browserSyncOptions: null,
  setPublicPath() { return this; },
  browserSync(options) { this.browserSyncOptions = options; return this; },
  sass() { return this; },
  js() { return this; },
  blocks() { return this; },
  extract() { return this; },
  copyWatched() { return this; },
  autoload() { return this; },
  options() { return this; },
  sourceMaps() { return this; },
  version() { return this; },
};
const originalLoad = Module._load;

Module._load = function(request, parent, isMain) {
  if (request === 'laravel-mix') return mix;
  if (request === '@tinypixelco/laravel-mix-wp-blocks' ||
      request === 'laravel-mix-purgecss' ||
      request === 'laravel-mix-copy-watched') return {};
  return originalLoad.call(this, request, parent, isMain);
};

require(process.env.WEBPACK_MIX);
if (!mix.browserSyncOptions ||
    mix.browserSyncOptions.proxy !== 'contraindicaciones.test' ||
    mix.browserSyncOptions.port !== 13000) {
  throw new Error(`Unexpected BrowserSync options: ${JSON.stringify(mix.browserSyncOptions)}`);
}
NODE

expect_abort() {
  local label=$1
  shift

  : > "$docker_calls"
  if "$@" > "$fixture_root/$label.log" 2>&1; then
    fail "Expected launcher failure: $label"
  fi
  [ ! -s "$docker_calls" ] || fail "Docker ran after preflight failure: $label"
}

expect_abort unresolved env FAKE_UNRESOLVED=1 PATH="$fake_bin:$PATH" DOCKER_ARGS="$docker_args" DOCKER_CALLS="$docker_calls" GETENT_ARGS="$getent_args" DSCACHEUTIL_ARGS="$dscacheutil_args" "$fake_theme/scripts/hot-development.sh"
expect_abort hmr-occupied env FAKE_OCCUPIED_PORT=8081 PATH="$fake_bin:$PATH" DOCKER_ARGS="$docker_args" DOCKER_CALLS="$docker_calls" GETENT_ARGS="$getent_args" DSCACHEUTIL_ARGS="$dscacheutil_args" "$fake_theme/scripts/hot-development.sh"
expect_abort browsersync-occupied env FAKE_OCCUPIED_PORT=3000 PATH="$fake_bin:$PATH" DOCKER_ARGS="$docker_args" DOCKER_CALLS="$docker_calls" GETENT_ARGS="$getent_args" DSCACHEUTIL_ARGS="$dscacheutil_args" "$fake_theme/scripts/hot-development.sh"
expect_abort non-numeric-port env HMR_PORT=invalid PATH="$fake_bin:$PATH" DOCKER_ARGS="$docker_args" DOCKER_CALLS="$docker_calls" GETENT_ARGS="$getent_args" DSCACHEUTIL_ARGS="$dscacheutil_args" "$fake_theme/scripts/hot-development.sh"
expect_abort reserved-port env HMR_PORT=1023 PATH="$fake_bin:$PATH" DOCKER_ARGS="$docker_args" DOCKER_CALLS="$docker_calls" GETENT_ARGS="$getent_args" DSCACHEUTIL_ARGS="$dscacheutil_args" "$fake_theme/scripts/hot-development.sh"
expect_abort invalid-browsersync-port env BROWSERSYNC_PORT=invalid PATH="$fake_bin:$PATH" DOCKER_ARGS="$docker_args" DOCKER_CALLS="$docker_calls" GETENT_ARGS="$getent_args" DSCACHEUTIL_ARGS="$dscacheutil_args" "$fake_theme/scripts/hot-development.sh"
expect_abort matching-ports env HMR_PORT=8081 BROWSERSYNC_PORT=8081 PATH="$fake_bin:$PATH" DOCKER_ARGS="$docker_args" DOCKER_CALLS="$docker_calls" GETENT_ARGS="$getent_args" DSCACHEUTIL_ARGS="$dscacheutil_args" "$fake_theme/scripts/hot-development.sh"

printf 'hot-development fixtures: ok\n'
