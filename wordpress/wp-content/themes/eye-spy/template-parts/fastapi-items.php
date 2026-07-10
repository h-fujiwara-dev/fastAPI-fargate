<?php
/**
 * FastAPI items list, shown at the bottom of the front page.
 *
 * @package Eye_Spy
 */
?>
<div class="card fastapi-items">
    <h2><?php esc_html_e('Items', 'eye-spy'); ?></h2>
    <?php echo do_shortcode('[fastapi_items]'); ?>
</div>
