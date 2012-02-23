# -*- coding: utf-8 -*-
require 'rubygems'
require 'vortex_client'
require 'json'
require 'nokogiri'
require 'pp'
require 'uri'
require 'pathname'

#------------------------------------------------------------#
# Change_links.rb written by Lise Hamre november 2009        #
# updated august 2011 Makes links relative and changes links #
#------------------------------------------------------------#

def make_link_folder_relative(link,wash)
  if(link and link.include?('/'))
    dir = File.dirname(link) +"/"
    puts "dir: " + dir
    new_link, wash = wash_link(dir,'',wash)
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

def change(type,href,doc,change_from,change_to,wash)
  linknum = 0
  doc.css(type).each do |element|
    link = element[href]
    if(link and link.include?(change_from))
      new_link = link.gsub(change_from,change_to)
      element.attributes[href].value = new_link
      puts " changed: " + link + " => " + new_link
      wash = true
      linknum += 1
    end
  end
  return linknum,doc,wash
end

def content_wash(json_data,tot_linknum,change_from,change_to,wash,property)
  content = json_data["properties"][property]
  doc = Nokogiri::HTML(content)
  a_linknum,doc,wash = change('a','href',doc,change_from,change_to,wash)
  tot_linknum += a_linknum
  img_linknum,doc,wash = change('img','src',doc,change_from,change_to,wash)
  tot_linknum += img_linknum
# puts "linknum: " + a_linknum.to_s
  if (a_linknum > 0 or img_linknum > 0)
    doc = doc.inner_html.gsub('<html>','').gsub('</html>','').gsub('<body>','').gsub('</body>','')
#    puts "doc: "+ doc
    json_data["properties"][property] = doc
  end
  return json_data,wash,tot_linknum
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
puts "Picture:"
      new_picture, wash = wash_link(picture,change_from,change_to,wash)
#    new_picture, picture_wash = make_link_folder_relative(picture,change_from,change_to,wash)
      if(new_picture and wash)
        json_data["properties"]["picture"] = new_picture.to_s
      end
#      json_data,wash,tot_linknum = content_wash(json_data,tot_linknum,change_from,change_to,wash,"caption",nil)
#      json_data,wash,tot_linknum = content_wash(json_data,tot_linknum,change_from,change_to,wash,"introduction",nil)
#      json_data,wash,tot_linknum = content_wash(json_data,tot_linknum,change_from,change_to,wash,"content",nil)
#      json_data,wash,tot_linknum = content_wash(json_data,tot_linknum,change_from,change_to,wash,"related-content",nil)

      if(wash)then
        item.content = json_data.to_json
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

if __FILE__ == $0
  change_from = "http://nyweb4.uio.no/"
  change_to = "/personer/lise/"
#  host = "https://nyweb4-dav.uio.no/"
#  project_folder = "/kunnskapsbasen/."
  host = "https://www-dav.vortex-demo.uio.no/" 
  project_folder = "/personer/lise/."
  get_file_content(host, project_folder, change_from, change_to)
end

