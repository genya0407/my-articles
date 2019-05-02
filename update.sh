#!/bin/zsh

set -ue

cd "$FEEDS_DIR"
git fetch
git reset --hard origin/master
bundle install --path vendor/bundle
cat "$ARTICLES_DIR"/feeds_me.toml | bundle exec ruby crawl.rb | bundle exec ruby generate.rb > dist/feeds.json

cd "$ARTICLES_DIR"
git pull
PKG_CONFIG_PATH=/usr/lib/imagemagick6/pkgconfig bundle install --path vendor/bundle
BLOG_FEED_PATH="$FEEDS_DIR"/dist/feeds.json bundle exec ruby site.rb
rm -rf /var/articles/*
cp -r _site/* /var/articles
