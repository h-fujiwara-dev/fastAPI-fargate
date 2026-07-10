<?php
/**
 * Eye Spy theme functions.
 *
 * @package Eye_Spy
 */

if (!defined('ABSPATH')) {
    exit;
}

function eyespy_setup(): void
{
    add_theme_support('title-tag');
    add_theme_support('post-thumbnails');
    add_theme_support('html5', ['search-form', 'comment-form', 'comment-list', 'gallery', 'caption']);
    register_nav_menus([
        'primary' => __('Primary Menu', 'eye-spy'),
    ]);
}
add_action('after_setup_theme', 'eyespy_setup');

function eyespy_enqueue_assets(): void
{
    $theme_version = (string) wp_get_theme()->get('Version');

    wp_enqueue_style('eyespy-style', get_stylesheet_uri(), [], $theme_version);

    wp_enqueue_script(
        'eyespy-eye-tracking',
        get_template_directory_uri() . '/assets/js/eye-tracking.js',
        [],
        $theme_version,
        true
    );
}
add_action('wp_enqueue_scripts', 'eyespy_enqueue_assets');
