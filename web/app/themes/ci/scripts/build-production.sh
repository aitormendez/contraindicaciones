#!/usr/bin/env bash
set -euo pipefail

theme_dir=$(cd "$(dirname "$0")/.." && pwd)
readonly node_image='node:14.21.3-bullseye@sha256:9b60cdcee9c6a27227689ebf4e7dd422ff195e978ffec360db5c0b3a05e20452'

docker run --rm --platform linux/amd64 \
  --user "$(id -u):$(id -g)" \
  --env HOME=/tmp \
  --env YARN_CACHE_FOLDER=/tmp/yarn-cache \
  --volume "$theme_dir:/app" \
  --workdir /app \
  "$node_image" \
  bash -lc 'yarn install --frozen-lockfile && yarn build:production'

"$theme_dir/scripts/verify-build.sh"
