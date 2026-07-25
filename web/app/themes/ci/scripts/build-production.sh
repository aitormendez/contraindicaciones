#!/usr/bin/env bash
set -euo pipefail

theme_dir=$(cd "$(dirname "$0")/.." && pwd)

docker run --rm --platform linux/amd64 \
  --user "$(id -u):$(id -g)" \
  --env HOME=/tmp \
  --env YARN_CACHE_FOLDER=/tmp/yarn-cache \
  --volume "$theme_dir:/app" \
  --workdir /app \
  node:14.21.3-bullseye \
  bash -lc 'yarn install --frozen-lockfile && yarn build:production'

"$theme_dir/scripts/verify-build.sh"
