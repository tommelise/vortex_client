# -*- coding: utf-8 -*-
require 'rubygems'
require 'vortex_client'
require 'json'
require 'nokogiri'
require 'pp'
require 'uri'
require 'pathname'
require 'pry'
require 'htmlentities'


def find_nullfiles(item)
  resourceType = item.propfind.xpath("//v:resourceType", "v" => "vrtx").first.text
  filename = item.url.path.to_s
  puts "Filename: " + filename
  ###binding.pry
  orig_filename = filename.gsub(".html","_orig.html")
  if resourceType == "html" and item.content.to_s =="null" and @vortex.exists?(orig_filename)
#    @files << { :filename => filename, :orig_filename => orig_filename }
    puts "sletter filen " + filename
    @vortex.delete(filename)
    puts "renamer " + orig_filename + " -> " + filename
    @vortex.move(orig_filename, filename)
  end
end


def delete_n_move(files)
  files.each do |pair|
    puts "sletter filen " + pair.filename
    @vortex.delete(pair.filename)
    puts "renamer " + pair.orig_filename + " -> " + pair.filename
    @vortex.move(pair.orig_filename, pair.filename)
  end
end

host = "https://foreninger-dav.uio.no/"
@vortex = Vortex::Connection.new(host,:use_osx_keychain => true)
@files = Array.new

def vortexfind(host)
  @vortex.find('/url/', :recursive => true, :filename=>/\.html$/) do |item|
    find_nullfiles(item)
    #  binding.pry
  end
end

vortexfind(host)

#delete_n_move(@files)
