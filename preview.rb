#! /usr/bin/env ruby
require "webrick"

WEBrick::HTTPServer.new(
  DocumentRoot: ARGV[0] || "./_site",
  Port: 8000,
).start
