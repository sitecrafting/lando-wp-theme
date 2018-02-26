#!/bin/bash


BOLD=$(tput bold)
NORMAL=$(tput sgr0)


# Set default defaults.
# These can be overridden by setting them in the script invocation, e.g.:
#
#  $ DEFAULT_URL=localhost:9999 setup-wordpress.bash
#
DEFAULT_URL=${DEFAULT_URL:-'https://lando-wp-theme.lndo.site'}
DEFAULT_TITLE=${DEFAULT_TITLE:-'Lando WP Theme'}
DEFAULT_ADMIN_USER=${DEFAULT_ADMIN_USER:-'admin'}
DEFAULT_ADMIN_PASSWORD=${DEFAULT_ADMIN_PASSWORD:-'password'}
DEFAULT_ADMIN_EMAIL=${DEFAULT_ADMIN_EMAIL:-'admin@example.com'}


# Install and configure WordPress if we haven't already
main() {
  echo 'Checking for WordPress config...'
  if wp_configured ; then
    echo 'WordPress is configured'
  else
    # create a wp-config.php
    wp --path=/var/www/html config create \
      --dbname=wordpress \
      --dbuser=wordpress \
      --dbpass=wordpress \
      --dbhost=database
  fi

  echo 'Checking for WordPress installation...'
  if wp_installed ; then
    echo 'WordPress is installed'
  else
    read -p "${BOLD}Site URL${NORMAL} ($DEFAULT_URL): " URL
    URL=${URL:-$DEFAULT_URL}

    read -p "${BOLD}Site Title${NORMAL} ($DEFAULT_TITLE): " TITLE
    TITLE=${TITLE:-$DEFAULT_TITLE}

    read -p "${BOLD}Admin username${NORMAL} ($DEFAULT_ADMIN_USER): " ADMIN_USER
    ADMIN_USER=${ADMIN_USER:-$DEFAULT_ADMIN_USER}

    read -p "${BOLD}Admin password${NORMAL} ($DEFAULT_ADMIN_PASSWORD): " ADMIN_PASSWORD
    ADMIN_PASSWORD=${ADMIN_PASSWORD:-$DEFAULT_ADMIN_PASSWORD}

    read -p "${BOLD}Admin email${NORMAL} ($DEFAULT_ADMIN_EMAIL): " ADMIN_EMAIL
    ADMIN_EMAIL=${ADMIN_EMAIL:-$DEFAULT_ADMIN_EMAIL}

    # install WordPress
    wp --path=/var/www/html core install \
      --url="$URL" \
      --title="$TITLE" \
      --admin_user="$ADMIN_USER" \
      --admin_password="$ADMIN_PASSWORD" \
      --admin_email="$ADMIN_EMAIL" \
      --skip-email
  fi

  echo 'Activating custom theme...'
  wp --path=/var/www/html theme activate custom-theme
}


# Detect whether WP has been configured already
wp_configured() {
  [[ $(wp config path 2>/dev/null) ]] && return
  false
}

# Detect whether WP is installed
wp_installed() {
  [[ $(wp core is-installed 2>/dev/null) ]] && return
  false
}


main