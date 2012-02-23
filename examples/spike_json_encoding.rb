# -*- coding: utf-8 -*-
require 'rubygems'
require 'vortex_client'
require 'json'
require 'uri'
require 'pathname'
require 'pry'


def json_doc(item,vortex)
  doc_data =  {
    "resourcetype" => "structured-article",
    "properties"   =>{
      "showAdditionalContent"=>"false", 
      "title"      => "En Blå overskrift", 
      "content"    => "En liten sær tekst med Blå røvere"
    }
  }
  puts "Output encoding: " + doc_data.to_json.to_s.encoding.name
  puts "Valid encoding: " + doc_data.to_json.to_s.valid_encoding?.to_s
  # binding.pry
  item.content = doc_data.to_json
#  vortex.put_string(filename, doc_data.to_json)
  vortex.proppatch(item.url.path.to_s,'<v:userSpecifiedCharacterEncoding xmlns:v="vrtx">utf-8</v:userSpecifiedCharacterEncoding>')
end

path = '/url/konv/testfile.html'
host = "https://foreninger-dav.uio.no/"
vortex = Vortex::Connection.new(host,:use_osx_keychain => true)

vortex.find(path,:recursive => true,:filename=>/\.html$/) do |item|
  json_doc(item,vortex)
end

vortex.find(path,:recursive => true,:filename=>/\.html$/) do |item|
  puts "Filename: " + item.url.path.to_s + " resourceType: " + item.propfind.xpath("//v:resourceType", "v" => "vrtx").first.text
  puts "Encoding: " + item.content.to_s.encoding.name
end
