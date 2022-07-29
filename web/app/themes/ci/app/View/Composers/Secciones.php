<?php

namespace App\View\Composers;

use Roots\Acorn\View\Composer;

class Secciones extends Composer {

    protected static $views = [
        'partials.content-secciones-page',
    ];

    public function override()
    {
        return [
            'cats' => $this->secs(),
        ];
    }

    public function secs()
    {
        $cats = get_categories();
        $output = '<ul class="categories">';

        $items = array_map(function ($cat) {
            return [
                'name' => $cat->name,
                'link' => get_category_link($cat->term_id),
                'slug' => $cat->slug,
                'cat_id' => $cat->term_id,
            ];
        }, $cats);

        foreach ($items as $item) {
            $output .= '<li class="cat-item cat-item-' . $item[cat_id] . '"><a href="' . $item[link] . '">' . $item[name] . '</a></li>';
        }

        $output .= '</ul>';

        return $output;
    }

}


