FROM devwithlando/php:7.0-apache


# Hack on a WordPress theme without having to install WordPress core on your host machine
LABEL maintainer="Coby Tamayo <ctamayo@sitecrafting.com>" license="MIT"

# Download WordPress core
ENV WORDPRESS_VERSION 4.9.4
ENV WORDPRESS_SHA1 xxx

# install WordPress core
RUN set -ex; \
  curl -o wordpress.tar.gz -fSL "https://wordpress.org/wordpress-${WORDPRESS_VERSION}.tar.gz"; \
  echo "$WORDPRESS_SHA1 *wordpress.tar.gz" | sha1sum -c -; \
  #
  # upstream tarballs include ./wordpress/ so this gives us /usr/src/wordpress
  #
  tar -xzf wordpress.tar.gz -C /var/www; \
  rm wordpress.tar.gz; \
  chown -R www-data:www-data /var/www/wordpress; \
  #
  # force a symlink to Lando default webroot to the wordpress install dir
  #
  rm -rf /var/www/html && ln -s /var/www/wordpress /var/www/html; \
  #
  # assume the /app mount point is just the *theme* directory!
  # this is what lets us mount the theme into a functional WP
  # container without installing WP core!
  #
  ln -s /app /var/www/wordpress/wp-content/themes/custom-theme

COPY ./scripts/setup-wordpress.bash /usr/local/bin/setup-wordpress.bash
