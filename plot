#!/bin/env ruby

require '.lib/basic.plt'
require "optparse"

options = {}
optparse = OptionParser.new do |opts|
  opts.banner = <<-EOS
Usage: `bundle exec ./plot FILE_NAME`

Options:


EOS

  opts.on("--title=TITLE", "-t=TITLE") {|x| options[:title] = x}
  opts.on("--services=SERVICES", "-s=SERVICES", Integer) {|x| options[:services] = x}
  opts.on("--output=OUTPUT", "-o=OUTPUT") {|x| options[:output] = x}
  opts.on("--extension=EXT", "-e=EXT") {|x| options[:ext] = x}
  opts.on("--imagesize=ARR", "-i=ARR",ARRAY) {|x| options[:size] = x}
  opts.on("--commands=LIST", "-c=LIST",ARRAY) {|x| options[:commands] = x}
# opts.on("--=", "-=") {|x| options[:] = x}
  opts.on("-h", "--help") {puts opts.banner && exit}
end
optparse.parse!

raise("No File Specified") if !ARGV[0]


`./lib/basic.plt ${args.to_s}`
