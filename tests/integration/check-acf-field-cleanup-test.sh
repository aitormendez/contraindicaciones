#!/usr/bin/env bash
set -euo pipefail

project_dir=$(cd "$(dirname "$0")/../.." && pwd)
check="$project_dir/tests/integration/check-acf-field.php"

: "${CONTRA_ALLOW_EPHEMERAL_TESTS:?Set CONTRA_ALLOW_EPHEMERAL_TESTS=1 only in the disposable test environment}"
: "${WP_ENV:?Set WP_ENV to the disposable WordPress environment}"
: "${WP_HOME:?Set WP_HOME to the loopback WordPress origin}"

if [ "$CONTRA_ALLOW_EPHEMERAL_TESTS" != 1 ] || [ "$WP_ENV" = production ]; then
  printf 'Refusing to run outside the disposable non-production environment\n' >&2
  exit 1
fi

case "$WP_HOME" in
  http://127.0.0.1|https://127.0.0.1|http://localhost|https://localhost|\
  http://127.0.0.1:*|https://127.0.0.1:*|http://localhost:*|https://localhost:*) ;;
  *)
    printf 'Refusing to run against a non-loopback WordPress origin\n' >&2
    exit 1
    ;;
esac

output_root=$(mktemp -d "${TMPDIR:-/tmp}/contra-acf-cleanup.XXXXXX")
chmod 700 "$output_root"

cleanup() {
  wp eval '
    global $wpdb;
    $ids = $wpdb->get_col($wpdb->prepare(
        "SELECT ID FROM {$wpdb->posts} WHERE post_title = %s",
        "acf-field-verification"
    ));
    foreach ($ids as $id) {
        wp_delete_post((int) $id, true);
    }
  ' > /dev/null 2>&1 || true

  rm -rf -- "$output_root"
}

trap cleanup EXIT

cd "$project_dir"

if CONTRA_ACF_FORCE_FAILURE_AFTER_CREATE=1 \
  wp eval-file "$check" > "$output_root/forced.log" 2>&1; then
  printf 'Expected the forced ACF failure to return a non-zero status\n' >&2
  exit 1
fi

if ! grep -Fq 'Forced failure after ephemeral post creation.' "$output_root/forced.log"; then
  printf 'Expected the forced ACF failure marker\n' >&2
  exit 1
fi

remaining=$(wp eval '
  global $wpdb;
  echo (int) $wpdb->get_var($wpdb->prepare(
      "SELECT COUNT(*) FROM {$wpdb->posts} WHERE post_title = %s",
      "acf-field-verification"
  ));
')

if [ "$remaining" != 0 ]; then
  printf 'Expected forced ACF cleanup to leave zero posts, got %s\n' "$remaining" >&2
  exit 1
fi

printf 'acf-forced-failure: status=failed-as-expected cleanup=ok\n'
