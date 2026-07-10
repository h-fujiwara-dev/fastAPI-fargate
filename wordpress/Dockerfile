FROM wordpress:6.9.4-php8.3-apache

# Baked outside /usr/src/wordpress on purpose: the stock entrypoint only
# copies wp-content/plugins|themes/<slug> from /usr/src/wordpress when it's
# missing at the destination, so a plugin or theme placed there would stop
# updating after the first deploy once wp-content lives on a persistent EFS
# volume. Our own wrapper entrypoint (below) force-copies these on every
# container start instead, so redeploys always win while everything else
# under wp-content (uploads, other plugins/themes) keeps persisting
# untouched. Theme *activation* is stored in the database, not on disk, so
# it isn't affected by this and only needs to be set once via wp-admin.
COPY wp-content/plugins/fastapi-items-viewer /usr/src/fastapi-items-viewer/fastapi-items-viewer
COPY wp-content/themes/eye-spy /usr/src/eye-spy/eye-spy

COPY docker-entrypoint-wrapper.sh /usr/local/bin/docker-entrypoint-wrapper.sh
RUN chmod +x /usr/local/bin/docker-entrypoint-wrapper.sh

ENTRYPOINT ["docker-entrypoint-wrapper.sh"]
CMD ["apache2-foreground"]
