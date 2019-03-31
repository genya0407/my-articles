#!/bin/zsh

set -ue

cd "$FEEDS_DIR"
git pull
bundle install --path vendor/bundle
cat ~/my-articles/feeds_me.toml | bundle exec ruby crawl.rb | bundle exec ruby generate.rb > dist/feeds.json

cd "$ARTICLES_DIR"
git pull
bundle install --path vendor/bundle
BLOG_FEED_PATH=~/feeds/dist/feeds.json bundle exec ruby site.rb
cp -r _site/* /var/articles
