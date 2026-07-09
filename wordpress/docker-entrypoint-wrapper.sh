#!/usr/bin/env bash
set -euo pipefail

# Force-sync our own plugin into wp-content on every start, so a new image
# always overwrites whatever an older deploy left on the persistent EFS
# volume. Everything else under wp-content (uploads, any other plugin/theme)
# is left alone.
plugin_dest="/var/www/html/wp-content/plugins/fastapi-items-viewer"
mkdir -p "$plugin_dest"
cp -a /usr/src/fastapi-items-viewer/fastapi-items-viewer/. "$plugin_dest/"
chown -R www-data:www-data "$plugin_dest"

exec docker-entrypoint.sh "$@"
