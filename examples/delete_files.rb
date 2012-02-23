# -*- coding: utf-8 -*-
require 'rubygems'
require 'vortex_client'
require 'uri'
require 'pathname'
require 'pry'


def vortexfind(host,folder)
  @vortex.find(folder, :recursive => true, :filename=>/\_orig.html$/) do |item|
    resourceType = item.propfind.xpath('//v:resourceType', 'v' => 'vrtx').first.text
    encoding = item.content.to_s.encoding.name
    filename = item.url.path.to_s
    newfilename = filename.gsub('_orig.html','.html')
#    if (resourceType == 'html' or resourceType =='xhtml10trans') and @vortex.exists?(newfilename) 
    if @vortex.exists?(newfilename) 
      @vortex.delete(filename)
      puts 'slettet:      ' + filename + ' ' + resourceType + ' ' + encoding
    else
      puts 'Ikke slettet: ' + filename + ' ' + resourceType + ' ' + encoding
    end
  end
end

host = 'https://foreninger-dav.uio.no/'
folder = '/url/prosjekter/'

@vortex = Vortex::Connection.new(host,:use_osx_keychain => true)

vortexfind(host,folder)
