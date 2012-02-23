require 'rubygems'
require 'open-uri'

content = open('http://www.stk.uio.no/til_nedlasting/Menn%20skaper%20rom%20for%20foreldreskap%20og%20familie.pdf').read

puts "Size:" + content.size.to_s
