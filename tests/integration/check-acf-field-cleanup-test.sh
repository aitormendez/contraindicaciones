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

generate_run_id() {
  php -r 'echo bin2hex(random_bytes(16));'
}

validate_run_id() {
  local candidate=$1

  if [ "${#candidate}" -ne 32 ]; then
    return 1
  fi

  case "$candidate" in
    *[!0-9a-f]*) return 1 ;;
  esac
}

run_id=${CONTRA_ACF_RUN_ID:-}

if [ -z "$run_id" ]; then
  run_id=$(generate_run_id)
fi

if ! validate_run_id "$run_id"; then
  printf 'CONTRA_ACF_RUN_ID must be exactly 32 lowercase hexadecimal characters\n' >&2
  exit 1
fi

homonym_guard=$(generate_run_id)
foreign_run_id=$(generate_run_id)

while [ "$foreign_run_id" = "$run_id" ]; do
  foreign_run_id=$(generate_run_id)
done

if ! validate_run_id "$homonym_guard" || ! validate_run_id "$foreign_run_id"; then
  printf 'Could not generate valid cleanup isolation identities\n' >&2
  exit 1
fi

output_root=$(mktemp -d "${TMPDIR:-/tmp}/contra-acf-cleanup.XXXXXX")
chmod 700 "$output_root"
homonym_id=''
foreign_id=''

cleanup_by_marker() {
  local meta_key=$1
  local meta_value=$2

  CONTRA_ACF_CLEANUP_META_KEY="$meta_key" \
  CONTRA_ACF_CLEANUP_META_VALUE="$meta_value" \
    wp eval '
      $metaKey = getenv("CONTRA_ACF_CLEANUP_META_KEY");
      $metaValue = getenv("CONTRA_ACF_CLEANUP_META_VALUE");

      if (
          ! in_array($metaKey, ["_contra_acf_test_run", "_contra_acf_homonym_guard"], true) ||
          ! is_string($metaValue) ||
          preg_match("/\\A[a-f0-9]{32}\\z/D", $metaValue) !== 1
      ) {
          throw new RuntimeException("Missing cleanup identity.");
      }

      $ids = get_posts([
          "post_type" => "post",
          "post_status" => "any",
          "numberposts" => -1,
          "fields" => "ids",
          "meta_key" => $metaKey,
          "meta_value" => $metaValue,
          "suppress_filters" => true,
      ]);

      foreach ($ids as $id) {
          $id = (int) $id;
          $marker = (string) get_post_meta($id, $metaKey, true);

          if (get_post_type($id) === "post" && hash_equals($metaValue, $marker)) {
              wp_delete_post($id, true);
          }
      }
    ' > /dev/null 2>&1 || true
}

cleanup() {
  cleanup_by_marker '_contra_acf_test_run' "$run_id"
  cleanup_by_marker '_contra_acf_test_run' "$foreign_run_id"
  cleanup_by_marker '_contra_acf_homonym_guard' "$homonym_guard"

  rm -rf -- "$output_root"
}

trap cleanup EXIT

cd "$project_dir"

create_marked_post() {
  local meta_key=$1
  local meta_value=$2

  CONTRA_ACF_CREATE_META_KEY="$meta_key" \
  CONTRA_ACF_CREATE_META_VALUE="$meta_value" \
    wp eval '
      $metaKey = getenv("CONTRA_ACF_CREATE_META_KEY");
      $metaValue = getenv("CONTRA_ACF_CREATE_META_VALUE");
      $postId = wp_insert_post([
          "post_type" => "post",
          "post_status" => "draft",
          "post_title" => "acf-field-verification",
          "post_content" => "synthetic cleanup isolation guard",
          "meta_input" => [$metaKey => $metaValue],
      ], true);

      if (is_wp_error($postId) || ! is_int($postId) || $postId < 1) {
          throw new RuntimeException("Could not create the cleanup isolation guard.");
      }

      echo $postId;
    '
}

assert_marked_post() {
  local post_id=$1
  local meta_key=$2
  local meta_value=$3

  CONTRA_ACF_ASSERT_POST_ID="$post_id" \
  CONTRA_ACF_ASSERT_META_KEY="$meta_key" \
  CONTRA_ACF_ASSERT_META_VALUE="$meta_value" \
    wp eval '
      $postId = (int) getenv("CONTRA_ACF_ASSERT_POST_ID");
      $metaKey = getenv("CONTRA_ACF_ASSERT_META_KEY");
      $metaValue = getenv("CONTRA_ACF_ASSERT_META_VALUE");
      $marker = (string) get_post_meta($postId, $metaKey, true);

      if (
          get_post_type($postId) !== "post" ||
          get_the_title($postId) !== "acf-field-verification" ||
          ! is_string($metaValue) ||
          ! hash_equals($metaValue, $marker)
      ) {
          throw new RuntimeException("The preexisting homonymous post did not survive unchanged.");
      }
    ' > /dev/null
}

homonym_id=$(create_marked_post '_contra_acf_homonym_guard' "$homonym_guard")
foreign_id=$(create_marked_post '_contra_acf_test_run' "$foreign_run_id")

if [ -z "$homonym_id" ] || [ -z "$foreign_id" ]; then
  printf 'Expected non-empty IDs for the cleanup isolation guards\n' >&2
  exit 1
fi

case "$homonym_id:$foreign_id" in
  *[!0-9:]*)
    printf 'Expected numeric IDs for the cleanup isolation guards\n' >&2
    exit 1
    ;;
esac

if CONTRA_ACF_RUN_ID="$run_id" \
  CONTRA_ACF_FORCE_FAILURE_AFTER_CREATE=1 \
  wp eval-file "$check" > "$output_root/forced.log" 2>&1; then
  printf 'Expected the forced ACF failure to return a non-zero status\n' >&2
  exit 1
fi

if ! grep -Fq 'Forced failure after tagged ephemeral post creation.' "$output_root/forced.log"; then
  printf 'Expected the tagged forced ACF failure marker\n' >&2
  exit 1
fi

if ! assert_marked_post "$homonym_id" '_contra_acf_homonym_guard' "$homonym_guard"; then
  printf 'Expected the preexisting homonymous post to survive the forced failure\n' >&2
  exit 1
fi

if ! assert_marked_post "$foreign_id" '_contra_acf_test_run' "$foreign_run_id"; then
  printf 'Expected a distinct ACF run identity to survive the forced failure\n' >&2
  exit 1
fi

remaining=$(CONTRA_ACF_QUERY_RUN_ID="$run_id" wp eval '
  $runId = getenv("CONTRA_ACF_QUERY_RUN_ID");

  if (! is_string($runId) || preg_match("/\\A[a-f0-9]{32}\\z/D", $runId) !== 1) {
      throw new RuntimeException("Missing ACF query identity.");
  }

  $ids = get_posts([
      "post_type" => "post",
      "post_status" => "any",
      "numberposts" => -1,
      "fields" => "ids",
      "meta_key" => "_contra_acf_test_run",
      "meta_value" => $runId,
      "suppress_filters" => true,
  ]);
  echo count($ids);
')

if [ "$remaining" != 0 ]; then
  printf 'Expected forced ACF cleanup to leave zero posts for its run ID, got %s\n' "$remaining" >&2
  exit 1
fi

printf 'acf-forced-failure: status=failed-as-expected cleanup=ok homonym=preserved isolation=ok\n'
