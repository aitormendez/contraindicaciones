<?php

namespace App\Fields;

use Log1x\AcfComposer\Field;
use StoutLogic\AcfBuilder\FieldsBuilder;

class Example extends Field
{
    /**
     * The field group.
     *
     * @return array
     */
    public function fields()
    {
        $cat_img = new FieldsBuilder('cat_img');

        $cat_img
            ->setLocation('taxonomy', '==', 'category');

        $cat_img
            ->addFile('img_cat', [
                'label' => 'Avatar categoría',
                'instructions' => 'Subir una imagen para la categoría',
                'return_format' => 'array',
            ]);

        return $cat_img->build();
    }
}
