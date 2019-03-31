require 'rakyll'
require 'httpclient'
require 'json'
require 'tmpdir'
require 'securerandom'

BLOG_FEED_PATH = ENV.fetch('BLOG_FEED_PATH')

ArticleAttributes = [:entry_url, :title, :abstract_html, :abstract, :icon_url, :published_at]
Article = Struct.new(*ArticleAttributes)

SourceFeed = Struct.new(:title, :url)

_articles = JSON.parse(File.read(BLOG_FEED_PATH), symbolize_names: true).map do |record|
  Article.new(*(ArticleAttributes.map { |k| record[k] }))
end.sort_by(&:published_at).reverse

articles = Dir.mktmpdir do |tmpdir|
  client = HTTPClient.new
  _articles.map do |article|
    unless article.icon_url.nil?
      thumbnail_fname = "#{SecureRandom.uuid}#{File.extname(article.icon_url)}"
      thumbnail_path = "#{tmpdir}/#{thumbnail_fname}"
      open(thumbnail_path, 'wb') do |file|
        client.get_content(article.icon_url) do |chunk|
          file.write chunk
        end
      end
      article.icon_url = "/static/thumbnails/#{thumbnail_fname}"
      FileUtils.copy(thumbnail_path, './static/thumbnails')
    end
    article
  end
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
