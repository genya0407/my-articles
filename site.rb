require 'rakyll'
require 'httpclient'
require 'json'
require 'tmpdir'
require 'securerandom'
require 'rmagick'

BLOG_FEED_PATH = ENV.fetch('BLOG_FEED_PATH')

ArticleAttributes = [:entry_url, :title, :abstract_html, :abstract, :icon_url, :published_at]
Article = Struct.new(*ArticleAttributes)

SourceFeed = Struct.new(:title, :url)

THUMBNAIL_DIR = 'static/thumbnails'

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

def compress_thumbnail(thumbnail_path, dest_dir, max_width: 200, max_height: 200)
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
      compressed_fname = compress_thumbnail("#{tmpdir}/#{original_fname}", tmpdir)
      FileUtils.copy("#{tmpdir}/#{compressed_fname}", THUMBNAIL_DIR)
      article.icon_url = "/#{THUMBNAIL_DIR}/#{compressed_fname}"
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
