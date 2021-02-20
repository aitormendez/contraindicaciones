<?php

namespace App\Fields;

use Log1x\AcfComposer\Field;
use StoutLogic\AcfBuilder\FieldsBuilder;

class Posts extends Field
{
    /**
     * The field group.
     *
     * @return array
     */
    public function fields()
    {
        $builder = new FieldsBuilder('cat_img');

        $builder
            ->setLocation('post_type', '==', 'post');

        $builder
            ->addTrueFalse('destacado', [
                'label' => 'Destacado',
                'instructions' => 'Marcar aquí para que aparezca en los destacados de portada',
                'default_value' => 0,
                'ui' => 1,
                'ui_on_text' => 'Ahora está destacado',
                'ui_off_text' => 'Ahora no está destacado',
            ]);

        return $builder->build();
    }
}
