<?php
/**
 * @package Eye_Spy
 */

get_header();
?>

<?php if (have_posts()) : ?>
    <?php while (have_posts()) : the_post(); ?>
        <article <?php post_class('card'); ?>>
            <h1><?php the_title(); ?></h1>
            <div class="entry-content">
                <?php the_content(); ?>
            </div>
        </article>
    <?php endwhile; ?>
<?php else : ?>
    <p><?php esc_html_e('Nothing found.', 'eye-spy'); ?></p>
<?php endif; ?>

<?php get_footer(); ?>
