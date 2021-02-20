<?php

namespace App\View\Composers;

use Roots\Acorn\View\Composer;
use WP_Query;

class Destacados extends Composer
{
    /**
     * List of views served by this composer.
     *
     * @var array
     */
    protected static $views = [
        'index',
    ];

    /**
     * Data to be passed to view before rendering, but after merging.
     *
     * @return array
     */
    public function with()
    {
        return [
            'destacados' => $this->destacados(),
        ];
    }

    /**
     * Returns posts destacados.
     *
     */
    public function destacados()
    {

        $destacados_query = new WP_Query([
            'post_type' => 'post',
            'posts_per_page'=>'5',
            'order' => 'DESC',
            'meta_query' => [
                [
                    'key'   => 'destacado',
                    'value' => '1',
                ]
            ]
        ]);

        return $destacados_query;
    }
}
