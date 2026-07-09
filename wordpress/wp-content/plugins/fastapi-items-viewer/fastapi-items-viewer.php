<?php
/**
 * Plugin Name: FastAPI Items Viewer
 * Description: Read-only list/detail view of the FastAPI backend's Items, via a shortcode. Calls the API server-side only — the API key never reaches the browser.
 * Version: 1.0.0
 * Requires PHP: 8.0
 * License: GPL-2.0-or-later
 */

if (!defined('ABSPATH')) {
    exit;
}

define('FIV_OPTION_API_BASE_URL', 'fastapi_items_viewer_api_base_url');
define('FIV_OPTION_API_KEY', 'fastapi_items_viewer_api_key');
define('FIV_QUERY_VAR', 'fastapi_item');

/**
 * Env vars (set on the ECS task) take precedence; the settings page is a
 * fallback for local/manual configuration.
 */
function fiv_get_api_base_url(): string
{
    $env = getenv('FASTAPI_API_BASE_URL');
    if ($env !== false && $env !== '') {
        return rtrim($env, '/');
    }
    return rtrim((string) get_option(FIV_OPTION_API_BASE_URL, ''), '/');
}

function fiv_get_api_key(): string
{
    $env = getenv('FASTAPI_API_KEY');
    if ($env !== false && $env !== '') {
        return $env;
    }
    return (string) get_option(FIV_OPTION_API_KEY, '');
}

/**
 * Calls GET {base_url}{path} with the X-API-Key header.
 * Returns the decoded JSON body on success, or a WP_Error on failure.
 */
function fiv_api_get(string $path)
{
    $base_url = fiv_get_api_base_url();
    $api_key = fiv_get_api_key();

    if ($base_url === '' || $api_key === '') {
        return new WP_Error('fiv_not_configured', 'FastAPI Items Viewer is not configured.');
    }

    $response = wp_remote_get($base_url . $path, [
        'headers' => ['X-API-Key' => $api_key],
        'timeout' => 8,
    ]);

    if (is_wp_error($response)) {
        return $response;
    }

    $status = wp_remote_retrieve_response_code($response);
    if ($status < 200 || $status >= 300) {
        return new WP_Error('fiv_bad_status', sprintf('Unexpected response status: %d', $status));
    }

    $body = json_decode(wp_remote_retrieve_body($response), true);
    if (!is_array($body)) {
        return new WP_Error('fiv_bad_body', 'Could not parse the API response.');
    }

    return $body;
}

/**
 * Renders a generic, escaped error message. Never echoes raw API/WP_Error
 * details to visitors — only logged server-side for admin debugging.
 */
function fiv_render_error(WP_Error $error): string
{
    error_log('[fastapi-items-viewer] ' . $error->get_error_message());
    return '<p class="fiv-error">' . esc_html__('Unable to load items right now.', 'fastapi-items-viewer') . '</p>';
}

function fiv_render_styles_once(): string
{
    static $printed = false;
    if ($printed) {
        return '';
    }
    $printed = true;

    return '<style>
        .fiv-list { list-style: none; margin: 0; padding: 0; }
        .fiv-list li { padding: 0.5em 0; border-bottom: 1px solid #ddd; }
        .fiv-list a { font-weight: 600; text-decoration: none; }
        .fiv-detail h3 { margin-bottom: 0.25em; }
        .fiv-detail .fiv-meta { color: #666; font-size: 0.9em; margin-bottom: 1em; }
        .fiv-back { display: inline-block; margin-bottom: 1em; }
        .fiv-error { color: #a00; }
    </style>';
}

function fiv_render_list(): string
{
    $items = fiv_api_get('/items');
    if (is_wp_error($items)) {
        return fiv_render_error($items);
    }

    if (empty($items)) {
        return '<p>' . esc_html__('No items found.', 'fastapi-items-viewer') . '</p>';
    }

    $html = '<ul class="fiv-list">';
    foreach ($items as $item) {
        $id = isset($item['id']) ? absint($item['id']) : 0;
        $name = isset($item['name']) ? (string) $item['name'] : '';
        $detail_url = esc_url(add_query_arg(FIV_QUERY_VAR, $id));
        $html .= sprintf(
            '<li><a href="%s">%s</a></li>',
            $detail_url,
            esc_html($name)
        );
    }
    $html .= '</ul>';

    return $html;
}

function fiv_render_detail(int $item_id): string
{
    $item = fiv_api_get('/items/' . $item_id);
    if (is_wp_error($item)) {
        return fiv_render_error($item);
    }

    $name = isset($item['name']) ? (string) $item['name'] : '';
    $description = isset($item['description']) && $item['description'] !== null
        ? (string) $item['description']
        : '';
    $created_at = isset($item['created_at']) ? (string) $item['created_at'] : '';

    $back_url = esc_url(remove_query_arg(FIV_QUERY_VAR));

    $html = '<a class="fiv-back" href="' . $back_url . '">&larr; ' . esc_html__('Back to list', 'fastapi-items-viewer') . '</a>';
    $html .= '<div class="fiv-detail">';
    $html .= '<h3>' . esc_html($name) . '</h3>';
    if ($created_at !== '') {
        $html .= '<p class="fiv-meta">' . esc_html($created_at) . '</p>';
    }
    if ($description !== '') {
        $html .= '<p>' . esc_html($description) . '</p>';
    }
    $html .= '</div>';

    return $html;
}

add_shortcode('fastapi_items', function (): string {
    $output = fiv_render_styles_once();

    $item_id = isset($_GET[FIV_QUERY_VAR]) ? absint(wp_unslash($_GET[FIV_QUERY_VAR])) : 0;

    if ($item_id > 0) {
        return $output . fiv_render_detail($item_id);
    }

    return $output . fiv_render_list();
});

// ---- Settings page (Settings > FastAPI Items) — fallback configuration ----

add_action('admin_menu', function (): void {
    add_options_page(
        'FastAPI Items',
        'FastAPI Items',
        'manage_options',
        'fastapi-items-viewer',
        'fiv_render_settings_page'
    );
});

add_action('admin_init', function (): void {
    register_setting('fiv_settings', FIV_OPTION_API_BASE_URL, ['sanitize_callback' => 'esc_url_raw']);
    register_setting('fiv_settings', FIV_OPTION_API_KEY, ['sanitize_callback' => 'sanitize_text_field']);

    add_settings_section('fiv_main', '', '__return_false', 'fastapi-items-viewer');

    add_settings_field(
        FIV_OPTION_API_BASE_URL,
        __('API base URL', 'fastapi-items-viewer'),
        function (): void {
            printf(
                '<input type="url" name="%s" value="%s" class="regular-text" placeholder="http://example.com" />',
                esc_attr(FIV_OPTION_API_BASE_URL),
                esc_attr(get_option(FIV_OPTION_API_BASE_URL, ''))
            );
        },
        'fastapi-items-viewer',
        'fiv_main'
    );

    add_settings_field(
        FIV_OPTION_API_KEY,
        __('API key', 'fastapi-items-viewer'),
        function (): void {
            printf(
                '<input type="password" name="%s" value="%s" class="regular-text" autocomplete="off" />',
                esc_attr(FIV_OPTION_API_KEY),
                esc_attr(get_option(FIV_OPTION_API_KEY, ''))
            );
        },
        'fastapi-items-viewer',
        'fiv_main'
    );
});

function fiv_render_settings_page(): void
{
    if (!current_user_can('manage_options')) {
        return;
    }
    ?>
    <div class="wrap">
        <h1><?php echo esc_html(get_admin_page_title()); ?></h1>
        <p>
            <?php esc_html_e(
                'These values are only used as a fallback when the FASTAPI_API_BASE_URL / FASTAPI_API_KEY environment variables are not set on the container.',
                'fastapi-items-viewer'
            ); ?>
        </p>
        <?php if (getenv('FASTAPI_API_BASE_URL') !== false || getenv('FASTAPI_API_KEY') !== false): ?>
            <p><strong><?php esc_html_e('Currently configured via environment variables — the fields below are not in effect.', 'fastapi-items-viewer'); ?></strong></p>
        <?php endif; ?>
        <form method="post" action="options.php">
            <?php
            settings_fields('fiv_settings');
            do_settings_sections('fastapi-items-viewer');
            submit_button();
            ?>
        </form>
        <p><?php esc_html_e('Usage: add the [fastapi_items] shortcode to any page or post.', 'fastapi-items-viewer'); ?></p>
    </div>
    <?php
}
