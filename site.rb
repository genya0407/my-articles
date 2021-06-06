require 'rakyll'
require 'httpclient'
require 'json'
require 'tmpdir'
require 'securerandom'
require 'rmagick'
require 'uri'
require 'listen'
require 'fileutils'

BLOG_FEED_PATH = ENV.fetch('BLOG_FEED_PATH')

ArticleAttributes = [:entry_url, :title, :abstract_html, :abstract, :icon_url, :published_at]
class Article < Struct.new(*ArticleAttributes)
  def hatebu_count
    @_hatebu_count ||= begin
      client = HTTPClient.new
      client
        .get_content("https://api.b.st-hatena.com/entry.count?url=#{URI.encode_www_form_component(self.entry_url)}")
        .to_i
    end
  end

  def hatebu_url
    @_hatebu_url ||= begin
      without_scheme = self.entry_url.sub(/https?:\/\//, '')
      "http://b.hatena.ne.jp/entry/s/#{without_scheme}"
    end
  end
end

SourceFeed = Struct.new(:title, :url)

FileUtils.rm_rf('_site/')
THUMBNAIL_DIR = 'static/thumbnails'
FileUtils.rm_rf(THUMBNAIL_DIR)
FileUtils.mkdir(THUMBNAIL_DIR)
File.write("#{THUMBNAIL_DIR}/.keep", '')

def download_thumbnail(icon_url, dest_dir)
  client = HTTPClient.new
  thumbnail_fname = "#{SecureRandom.uuid}#{File.extname(icon_url)}"
  thumbnail_path = "#{dest_dir}/#{thumbnail_fname}"
  open(thumbnail_path, 'wb') do |file|
    client.get_content(icon_url) do |chunk|
      file.write chunk
    end
  end

  return thumbnail_fname
end

def read_background_white(image_path)
  img_list = Magick::ImageList.new
  img_list.read(image_path)
  img_list.new_image(img_list.first.columns, img_list.first.rows) { self.background_color = "white" }
  img_list.reverse.flatten_images
end

def resize_thumbnail(thumbnail_path, dest_dir, max_width: 200, max_height: 200)
  img = read_background_white(thumbnail_path)
  new_img = img.resize_to_fit(max_width, max_height)
  new_img.background_color = 'white'
  new_fname = "#{SecureRandom.uuid}.jpg"
  new_img.write("#{dest_dir}/#{new_fname}")
  return new_fname
end

_articles = JSON.parse(File.read(BLOG_FEED_PATH), symbolize_names: true).map do |record|
  Article.new(*(ArticleAttributes.map { |k| record[k] }))
end.sort_by(&:published_at).reverse

articles = Dir.mktmpdir do |tmpdir|
  _articles.map do |article|
    unless article.icon_url.nil?
      original_fname = download_thumbnail(article.icon_url, tmpdir)
      resized_fname = resize_thumbnail("#{tmpdir}/#{original_fname}", tmpdir)
      FileUtils.copy("#{tmpdir}/#{resized_fname}", THUMBNAIL_DIR)
      article.icon_url = "/#{THUMBNAIL_DIR}/#{resized_fname}"
    end
    article
  end
end

rakyll = proc do
  Rakyll.dsl do
    copy 'static/*/*'

    create 'index.html' do
      @source_feeds = [
        SourceFeed.new('さんちゃのブログ', 'https://dawn.hateblo.jp'),
        SourceFeed.new('さんちゃのブログ 2nd', 'https://genya0407.github.io/'),
        SourceFeed.new('genya0407 - Qiita', 'https://qiita.com/genya0407')
      ]
      @articles = articles
      @default_icon_url = '/static/images/default.jpg'
      apply 'index.html.erb'
    end
  end

  puts "[#{Time.now}] Generated."
end

rakyll.call

SITE_URL = 'https://articles.kuminecraft.xyz'

feed = proc do
  require "rss"

  rss = RSS::Maker.make('atom') do |maker|
    maker.channel.about = "#{SITE_URL}/feed.xml"
    maker.channel.title = "genya0407's articles"
    maker.channel.description = "genya0407が書いたもの"
    maker.channel.link = SITE_URL
    maker.channel.author = 'Yusuke Sangenya'
    maker.channel.date = articles.first.published_at

    maker.items.do_sort = true

    articles.each do |article|
      maker.items.new_item do |item|
        item.link = article.entry_url
        item.title = article.title
        item.date = article.published_at
        item.description = article.abstract
      end
    end

    maker.image.title = 'Array-san'
    maker.image.url = "#{SITE_URL}/static/images/array-san.jpg"
  end

  File.write('_site/feed.xml', rss.to_s)
end

feed.call

if ARGV[0] == 'watch'
  listener = Listen.to 'templates' do
    rakyll.call
    feed.call
  end
  listener.start
  sleep
end
