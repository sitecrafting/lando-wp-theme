#!/bin/bash

usage() {
  echo 'update.bash [-h|--help] [-d|--dry-run]'
}

POSITIONAL=()
while [[ $# -gt 0 ]] ; do
  key="$1"

  case $key in
    -d|--dry-run)
    DRY_RUN="1"
    shift # next opt
    ;;
    -h|--help)
    usage
    exit
    shift
    ;;
  esac
done

DRY_RUN=${DRY_RUN:-''}

main() {
  # First make sure we're on master and starting at the latest version we have
  reset_cwd

  # Establish the Source of Truth
  LATEST_WORDPRESS_CHECKSUM_URL='https://wordpress.org/wordpress-latest.tar.gz.sha1'
  LATEST_WORDPRESS_DOWNLOAD_URL='https://wordpress.org/wordpress-latest.tar.gz'

  # what's the latest available version's checksum?
  latest_checksum=$(get_latest_checksum)

  # what version are we at?
  current_checksum=$(get_current_checksum)

  if [[ $latest_checksum = $current_checksum ]] ; then
    echo 'no update available'
    exit
  else
    echo "update available!"
    latest_version=$(get_latest_version)
    update $latest_version $latest_checksum
  fi
}


reset_cwd() {
  git reset --hard
  git clean -fd
  git fetch --tags
  git checkout master
  git pull origin master
}


get_latest_checksum() {
  # log curl errors, but not progess
  error_log="log/$(date +%Y-%m-%d-%H:%M).log"
  curl -Ss $LATEST_WORDPRESS_CHECKSUM_URL 2>$error_log

  # cleanup; only keep logs with errors
  if [[ -z $(cat $error_log) ]] ; then
    rm -f $error_log
  fi
}


get_current_checksum() {
  egrep 'ENV WORDPRESS_SHA1 .+' ./Dockerfile | awk '{print $3}'
}


get_latest_version() {
  # Download wordpress
  curl -Ss -o wordpress.tar.gz $LATEST_WORDPRESS_DOWNLOAD_URL
  # unarchive it
  tar -xzf wordpress.tar.gz -C .
  # check the latest version
  php -r 'include "wordpress/wp-includes/version.php"; echo $wp_version;'
}


update() {
  sed -i '' "s/^ENV WORDPRESS_VERSION .*/ENV WORDPRESS_VERSION $latest_version/" Dockerfile
  sed -i '' "s/^ENV WORDPRESS_SHA1 .*/ENV WORDPRESS_SHA1 $latest_checksum/" Dockerfile
  sed -i '' "s/^Current version: .*/Current version: `$latest_version`/" README.md

  if [[ $DRY_RUN ]] ; then
    echo 'exiting after dry run'
  fi

  # build and tag Docker image
  DOCKER_IMAGE=${DOCKER_IMAGE:-'sitecrafting/lando-wp-theme'}
  docker build -t "$DOCKER_IMAGE:$latest_version" .
  docker tag "$DOCKER_IMAGE:$latest_version" "$DOCKER_IMAGE:latest"

  # push docker image if we can
  if [[ -f .env ]] ; then
    source .env

    # attempt login
    docker login --username $DOCKER_USERNAME --password $DOCKER_PASSWORD
    if [[ "$?" ]] ; then
      docker push "$DOCKER_IMAGE:$latest_version"
      docker push "$DOCKER_IMAGE:latest"
    fi
  fi

  git checkout -b "v$latest_version" master
  git commit --all -m "bump version to $latest_version"
  git tag -am "tag for wordpress release $latest_version" "$latest_version"
  git push origin "v$latest_version"
}


main