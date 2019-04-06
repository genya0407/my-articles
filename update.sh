#!/bin/zsh

set -ue

cd "$FEEDS_DIR"
git pull
bundle install --path vendor/bundle
cat "$ARTICLES_DIR"/feeds_me.toml | bundle exec ruby crawl.rb | bundle exec ruby generate.rb > dist/feeds.json

cd "$ARTICLES_DIR"
git pull
PKG_CONFIG_PATH=/usr/lib/imagemagick6/pkgconfig bundle install --path vendor/bundle
BLOG_FEED_PATH="$FEEDS_DIR"/dist/feeds.json bundle exec ruby site.rb
cp -r _site/* /var/articles
