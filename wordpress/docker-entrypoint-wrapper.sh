#!/usr/bin/env bash
set -euo pipefail

# Force-sync our own plugin and theme into wp-content on every start, so a
# new image always overwrites whatever an older deploy left on the
# persistent EFS volume. Everything else under wp-content (uploads, any
# other plugin/theme) is left alone.
#
# Plain `cp -r` (not `-a`/`-p`): the EFS access point enforces uid/gid 33
# (www-data) on every write through this mount, so attempting to preserve
# the image's root:root ownership (or chown afterward) fails with EPERM.
# New files land as 33:33 automatically — no explicit chown needed.
plugin_dest="/var/www/html/wp-content/plugins/fastapi-items-viewer"
mkdir -p "$plugin_dest"
cp -r /usr/src/fastapi-items-viewer/fastapi-items-viewer/. "$plugin_dest/"

theme_dest="/var/www/html/wp-content/themes/eye-spy"
mkdir -p "$theme_dest"
cp -r /usr/src/eye-spy/eye-spy/. "$theme_dest/"

exec docker-entrypoint.sh "$@"
