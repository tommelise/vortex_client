# -*- coding: iso-8859-1 -*-
# related_content
#
# Author: Lise Hamre

require 'rubygems'
require 'vortex_client'


def find_files(rel_path)  
  @vortex.find(rel_path,:recursive => true,:filename=>/\.pjpg$/) do |item|
    puts item.uri.to_s
  end
end
  
host = "https://nyweb4-dav.uio.no/"
rel_path = "/publikasjoner/."

#host = "https://www-dav.vortex-demo.uio.no"
#rel_path = "/personer/lise/."

@vortex = Vortex::Connection.new(host,:use_osx_keychain => true)


find_files(rel_path)
