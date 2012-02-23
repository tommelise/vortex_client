# -*- coding: utf-8 -*-
require 'rubygems'
require 'vortex_client'
require 'json'
require 'nokogiri'
require 'pp'
require 'uri'
require 'pathname'

#-------------------------------------------------------#
# Change_links.rb written by Lise Hamre september 2011  #
# Makes picture folder-relative or changes picture link #
#-------------------------------------------------------#

def make_link_folder_relative(link,wash)
  if(link and link.include?('/'))
    dir = File.dirname(link) +"/"
    puts "dir: " + dir
    new_link, wash = wash_link(link,dir,'',wash)
  end
  return new_link,wash
end

def wash_link(link,change_from,change_to,wash)
  new_link = link.to_s.gsub(change_from,change_to)
    if not link.eql?(new_link)
      puts "link: " + link.to_s + "-> New link: " + new_link
      wash = true
    end
  return new_link,wash
end

def get_file_content(host, project_folder, change_from, change_to)
  vortex = Vortex::Connection.new(host,:use_osx_keychain => true)
  tot_linknum = 0
  linknum = 0
  filenum = 0
  wash = false
  vortex.find(project_folder, :recursive => true, :filename=>/\.html$/) do |item|
    filenum += 1
    puts 
    puts "Checking    : " + filenum.to_s + ": " + item.url.to_s
    begin
      json_data = JSON.parse(item.content) 
    rescue
      puts "Warning. Bad document. Not json:" + item.uri.to_s
    end
    if(json_data)
      picture = json_data["properties"]["picture"]
#      new_picture, wash = wash_link(picture,change_from,change_to,wash)
      new_picture, wash = make_link_folder_relative(picture,wash)
      if(new_picture and wash)
        json_data["properties"]["picture"] = new_picture.to_s
##        item.content = json_data.to_json
        puts "Updating    : " + item.url.to_s
#exit
        puts
        wash = false
      end
    end
  end
  puts "Done"
  puts "checked " + filenum.to_s + " file(s)"
  puts "changed " + tot_linknum.to_s + " links"
end

change_from = "/ny-web"
change_to = ""

#host = "https://www-dav.cees.uio.no/"
#project_folder = "/people/."

#host = "https://www-dav.st-petersburg.uio.no/"
#project_folder = "/ny-web/."

# host = "https://www-dav.vortex-demo.uio.no/" 
# project_folder = "/personer/lise/."
get_file_content(host, project_folder, change_from, change_to)

