# -*- coding: utf-8 -*-
require 'rubygems'
require 'vortex_client'
require 'json'
require 'nokogiri'
require 'pp'
require 'uri'
require 'pathname'
require 'pry'

#------------------------------------------------------#
# search_replace.rb written by Lise Hamre september 2011 #
# replaces contents                                    #
#------------------------------------------------------#


# Simple logger
def write_log(logfil)
  @log=  "<html>\n" +
    "  <head><title>Report</title></head>\n" +
    "  <body>\n" +
    "    <h1>" + Time.now.iso8601 + "<br>\nChangelog - Changed occurances</h1>\n" + 
    @log + 
    "  </body>\n" +
    "</html>\n"
  File.open(logfil, 'w') do |f|
    f.write(@log)
  end
  puts "\nChangelog written to file: " + logfil
end

def search_n_replace(folder)
  filenum = 0
  occ = 0
  @vortex.find(folder, :recursive => true, :filename=>/\.html$/) do |item|
    puts "url: " + item.url.to_s
    filenum += 1
    begin
      json_data = JSON.parse(item.content)
    rescue
      puts "Not json:" + item.uri.to_s
    end
    if json_data
      content = json_data["properties"]["content"]
    else 
      content = item.content
    end
    doc = Nokogiri::HTML(content.to_s)
    dirty = false
    doc.css('img').each do |element|
      if element.to_s[/bord.*jpg/]
        element.remove
        puts "removing : " + element.text + " from " + item.url.to_s
        @log += "removing : " + element.text + " from " + item.url.to_s+ "<br>\n"
        dirty = true
        occ += 1
      end
    end
    if(dirty)
      if json_data
        json_data["properties"]["content"] = doc.css("body").children.to_s
#       item.content = json_data.to_json
      else 
#       item.content = doc.to_s
      end
    end
  end
  return occ, filenum
end

host = "https://foreninger-dav.uio.no/"
@vortex = Vortex::Connection.new(host,:use_osx_keychain => true)
@log =""
logfile = "bil-vask-log.html"
folders = ["/bil/ny-web/grupper/sykkel/."]

folders.each do |folder|
  puts
  puts "Folder: " + folder
  @log += "<h2>" + folder + "</h2>\n"
  occ, filenum = search_n_replace(folder)
  puts "checked " + filenum.to_s + " file(s)"
  @log += "checked " + filenum.to_s + " file(s)" + "<br>\n"
  puts "changed " + occ.to_s + " file(s)" 
  @log += "changed " + occ.to_s + " file(s)<br><br>\n\n"
end

#write_log(logfile)
puts "Done"
