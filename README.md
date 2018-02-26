# Lando WordPress Theme

A docker image for hacking on a WordPress theme without installing core

## Usage

Designed for usage with Lando:

```yaml
# .lando.yml
name: lando-wp-theme
recipe: wordpress

services:
  appserver:
    type: php:custom

    overrides:
      services:
        image: sitecrafting/lando-wp-theme
        environment:
          LANDO_WEBROOT: /var/www/html
          # specify defaults to setup-wordpress.bash
          DEFAULT_URL: 'https://lando-wp-theme.lndo.site'
          DEFAULT_TITLE: 'My Beautiful Site'
          DEFAULT_ADMIN_USER: 'admin'
          DEFAULT_ADMIN_PASSWORD: 'password'
          DEFAULT_ADMIN_EMAIL: 'admin@example.com'

tooling:
  install:
    service: appserver
    cmd: setup-wordpress.bash
    description: 'Install and configure WordPress for custom theme dev'

  w:
    service: appserver
    cmd: 'wp --path=/var/www/html'
    description: 'Run wp-cli commands within the container webroot'
```

## Versioning

This repo is versioned in lockstep with WordPress production releases. Hopefully.

Current version: `4.9.4`
