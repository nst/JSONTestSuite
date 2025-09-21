#!/usr/bin/ruby

require 'json'

f = ARGV[0]

begin
    puts(f)
    json = File.read(f)
    JSON.parse(json)
    exit 0
rescue JSON::ParserError => e
    puts(e)
    exit 1
end
