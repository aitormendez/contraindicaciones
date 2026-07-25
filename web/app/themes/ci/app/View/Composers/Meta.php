<?php

namespace App\View\Composers;

use Roots\Acorn\View\Composer;

class Meta extends Composer
{
    /**
     * List of views served by this composer.
     *
     * @var array
     */
    protected static $views = [
        'partials.entry-meta',
    ];

    /**
     * Data to be passed to view before rendering, but after merging.
     *
     * @return array
     */
    public function with()
    {
        return [
            'cats' => $this->cats(),
        ];
    }

    public static function cats()
    {
        $cats = get_the_category();
        $output = '<ul class="categories">';

        $items = array_map(function ($cat) {
            return [
                'name' => $cat->name,
                'link' => get_category_link($cat->term_id),
                'slug' => $cat->slug,
            ];
        }, $cats);

        foreach ($items as $item) {
            $output .= sprintf(
                '<li class="%s"><a href="%s">%s</a></li>',
                esc_attr('cat'),
                esc_url($item['link']),
                esc_html($item['name'])
            );
        }

        $output .= '</ul>';

        return $output;
    }
}
