require 'rakyll'
require 'httpclient'
require 'json'
require 'tmpdir'
require 'securerandom'

BLOG_FEED_PATH = ENV.fetch('BLOG_FEED_PATH')

ArticleAttributes = [:entry_url, :title, :abstract_html, :abstract, :icon_url, :published_at]
Article = Struct.new(*ArticleAttributes)

SourceFeed = Struct.new(:title, :url)

THUMBNAIL_DIR = 'static/thumbnails'

def download_thumbnail(icon_url)
  client = HTTPClient.new
  thumbnail_fname = "#{SecureRandom.uuid}#{File.extname(icon_url)}"
  thumbnail_path = "#{THUMBNAIL_DIR}/#{thumbnail_fname}"
  open(thumbnail_path, 'wb') do |file|
    client.get_content(icon_url) do |chunk|
      file.write chunk
    end
  end

  return thumbnail_fname
end

_articles = JSON.parse(File.read(BLOG_FEED_PATH), symbolize_names: true).map do |record|
  Article.new(*(ArticleAttributes.map { |k| record[k] }))
end.sort_by(&:published_at).reverse

articles = _articles.map do |article|
  unless article.icon_url.nil?
    article.icon_url = "/#{THUMBNAIL_DIR}/#{download_thumbnail(article.icon_url)}"
  end
  article
end

Rakyll.dsl do
  copy 'static/*/*'

  create 'index.html' do
    @source_feeds = [
      SourceFeed.new('さんちゃのブログ', 'https://dawn.hateblo.jp'),
      SourceFeed.new('genya0407 - Qiita', 'https://qiita.com/genya0407')
    ]
    @articles = articles
    @default_icon_url = '/static/images/default.jpg'
    apply 'index.html.erb'
  end
end
