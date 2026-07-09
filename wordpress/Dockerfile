FROM wordpress:6.9.4-php8.3-apache

# Baked outside /usr/src/wordpress on purpose: the stock entrypoint only
# copies wp-content/plugins/<slug> from /usr/src/wordpress when it's missing
# at the destination, so a plugin placed there would stop updating after the
# first deploy once wp-content lives on a persistent EFS volume. Our own
# wrapper entrypoint (below) force-copies this plugin on every container
# start instead, so redeploys always win while everything else under
# wp-content (uploads, other plugins/themes) keeps persisting untouched.
COPY wp-content/plugins/fastapi-items-viewer /usr/src/fastapi-items-viewer/fastapi-items-viewer

COPY docker-entrypoint-wrapper.sh /usr/local/bin/docker-entrypoint-wrapper.sh
RUN chmod +x /usr/local/bin/docker-entrypoint-wrapper.sh

ENTRYPOINT ["docker-entrypoint-wrapper.sh"]
CMD ["apache2-foreground"]
