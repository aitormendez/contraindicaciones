<?php

use App\Fields\Posts;
use App\View\Composers\Destacados;
use Log1x\AcfComposer\Providers\AcfComposerServiceProvider;

$ensure = static function (bool $condition, string $message): void {
    if (! $condition) {
        throw new RuntimeException($message);
    }
};

$reportFailure = static function (Throwable $failure): never {
    if (defined('WP_CLI') && WP_CLI) {
        WP_CLI::error($failure->getMessage());
    }

    throw $failure;
};

try {
    $ensure(
        getenv('CONTRA_ALLOW_EPHEMERAL_TESTS') === '1',
        'Set CONTRA_ALLOW_EPHEMERAL_TESTS=1 only inside the disposable test environment.'
    );
    $ensure(defined('WP_ENV') && WP_ENV !== 'production', 'Refusing to run against a production environment.');

    $homeHost = parse_url(home_url('/'), PHP_URL_HOST);
    $ensure(
        in_array($homeHost, ['127.0.0.1', 'localhost'], true),
        'Refusing to run against a non-loopback WordPress origin.'
    );

    $application = app();
    $loadedProviders = $application->getLoadedProviders();
    $ensure(
        isset($loadedProviders[AcfComposerServiceProvider::class]),
        'The ACF Composer service provider is not loaded.'
    );
    $ensure($application->bound('AcfComposer'), 'The ACF Composer binding is missing.');
    $ensure(
        $application->make('AcfComposer')->getComposer(Posts::class) instanceof Posts,
        'App\\Fields\\Posts was not discovered.'
    );

    $group = acf_get_local_field_group('group_cat_img');
    $field = acf_get_local_field('field_cat_img_destacado');

    $ensure(is_array($group), 'group_cat_img is not registered in WordPress.');
    $ensure(is_array($field), 'field_cat_img_destacado is not registered in WordPress.');
    $ensure(($field['name'] ?? null) === 'destacado', 'The destacado field name changed.');
} catch (Throwable $failure) {
    $reportFailure($failure);
}

$postId = null;
$failure = null;
$cleanupFailure = null;

try {
    $insertedPost = wp_insert_post([
        'post_type' => 'post',
        'post_status' => 'publish',
        'post_title' => 'acf-field-verification',
        'post_content' => 'ephemeral functional verification',
    ], true);

    if (is_int($insertedPost)) {
        $postId = $insertedPost;
    }

    $ensure(! is_wp_error($insertedPost), 'The ephemeral post could not be created.');
    $ensure(is_int($postId) && $postId > 0, 'The ephemeral post ID is invalid.');

    $ensure(
        getenv('CONTRA_ACF_FORCE_FAILURE_AFTER_CREATE') !== '1',
        'Forced failure after ephemeral post creation.'
    );

    update_field('field_cat_img_destacado', 1, $postId);
    clean_post_cache($postId);

    $ensure(
        (string) get_field('field_cat_img_destacado', $postId, false) === '1',
        'The enabled ACF value did not survive a reload.'
    );
    $ensure(get_post_meta($postId, 'destacado', true) === '1', 'The enabled meta value was not persisted.');
    $ensure(
        get_post_meta($postId, '_destacado', true) === 'field_cat_img_destacado',
        'The ACF field reference meta was not persisted.'
    );

    $featured = (new Destacados)->destacados();
    $ensure(in_array($postId, wp_list_pluck($featured->posts, 'ID'), true), 'The enabled post is absent from destacados.');

    update_field('field_cat_img_destacado', 0, $postId);
    clean_post_cache($postId);

    $ensure(
        (string) get_field('field_cat_img_destacado', $postId, false) === '0',
        'The disabled ACF value did not survive a reload.'
    );
    $ensure(get_post_meta($postId, 'destacado', true) === '0', 'The disabled meta value was not persisted.');

    $featured = (new Destacados)->destacados();
    $ensure(! in_array($postId, wp_list_pluck($featured->posts, 'ID'), true), 'The disabled post remains in destacados.');
} catch (Throwable $caughtFailure) {
    $failure = $caughtFailure;
} finally {
    if (is_int($postId) && $postId > 0) {
        try {
            wp_delete_post($postId, true);
            $ensure(get_post_status($postId) === false, 'The ephemeral post was not deleted.');
        } catch (Throwable $caughtCleanupFailure) {
            $cleanupFailure = $caughtCleanupFailure;
        }
    }

    try {
        wp_reset_postdata();
    } catch (Throwable $caughtCleanupFailure) {
        $cleanupFailure ??= $caughtCleanupFailure;
    }
}

if ($cleanupFailure instanceof Throwable) {
    $cleanupMessage = 'Cleanup failed: '.$cleanupFailure->getMessage();
    $failure = $failure instanceof Throwable
        ? new RuntimeException($failure->getMessage().'; '.$cleanupMessage, 0, $failure)
        : new RuntimeException($cleanupMessage, 0, $cleanupFailure);
}

if ($failure instanceof Throwable) {
    $reportFailure($failure);
}

fwrite(STDOUT, "acf-functional: provider=ok discovery=ok registration=ok persistence=ok query=ok cleanup=ok\n");
