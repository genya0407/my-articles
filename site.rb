require 'rakyll'
require 'httpclient'
require 'json'

BLOG_FEED_URL = ENV.fetch('BLOG_FEED_URL')

ArticleAttributes = [:entry_url, :title, :abstract_html, :abstract, :icon_url, :published_at]
Article = Struct.new(*ArticleAttributes)

SourceFeed = Struct.new(:title, :url)

Rakyll.dsl do
  copy 'static/*/*'

  create 'index.html' do
    @source_feeds = [
      SourceFeed.new('さんちゃのブログ', 'https://dawn.hateblo.jp'),
      SourceFeed.new('genya0407 - Qiita', 'https://qiita.com/genya0407')
    ]
    @articles = JSON.parse(HTTPClient.get_content(BLOG_FEED_URL), symbolize_names: true).map do |record|
      Article.new(*(ArticleAttributes.map { |k| record[k] }))
    end.sort_by(&:published_at).reverse
    @default_icon_url = '/static/images/default.jpg'
    apply 'index.html.erb'
  end
end
