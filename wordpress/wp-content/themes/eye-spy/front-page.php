<?php
/**
 * Front page template: the eye-tracking hero, followed by the front page's
 * own content (if any).
 *
 * @package Eye_Spy
 */

get_header();
?>

<?php get_template_part('template-parts/eye-hero'); ?>

<?php if (have_posts()) : ?>
    <?php while (have_posts()) : the_post(); ?>
        <?php if (get_the_content()) : ?>
            <article <?php post_class('card'); ?>>
                <div class="entry-content">
                    <?php the_content(); ?>
                </div>
            </article>
        <?php endif; ?>
    <?php endwhile; ?>
<?php endif; ?>

<?php get_footer(); ?>
