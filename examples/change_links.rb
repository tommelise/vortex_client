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
# Change_links.rb written by Lise Hamre september 2011 #
# replaces contents                                    #
#------------------------------------------------------#


def get_file_content(project_folder, change_from, change_to)
  filenum = 0
  occ = 0
  tot_occ = 0
  @vortex.find(project_folder, :recursive => true, :filename=>/\.xml$/) do |item|
    filenum += 1
    #    puts "Checking    : " + filenum.to_s + ": " + item.url.to_s
    #    @log += "Checking    : " + filenum.to_s + ": " + item.url.to_s + "\n"
    doc = item.content
#    binding.pry
    occ = doc.scan(change_from).size
    tot_occ += occ
    new_doc = doc.gsub(change_from,change_to)
    if(occ>0)then
      puts "occ: " + occ.to_s
      @log +=  "occ: " + occ.to_s + "<br>\n"
#      item.content = new_doc
      puts "Updating    : " + item.url.to_s
      @log += "Updating    : " + item.url.to_s + "<br>\n"
      puts
      occ = 0
    end
  end
  puts "Done"
  puts "checked " + filenum.to_s + " file(s)"
  @log += "checked " + filenum.to_s + " file(s)" + "<br>\n"
  puts "changed " + tot_occ.to_s + " occurances of '" + change_from + "' to '" + change_to +"'"
  @log += "changed " + tot_occ.to_s + " occurances of '" + change_from + "' to '" + change_to +"'" + "<br><br>\n\n"
end

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


@log =""

# host = "https://www-dav.vortex-demo.uio.no/" 
# project_folder = "/personer/lise/."

#host = "https://nyweb4-dav.uio.no/"
#change_from = '<img alt="" height="20" src="/bil/sykkel/medlemskap/bord%201.jpg" width="524"/>'
#change_to = ""
#logfile = "hl-lenkevask-log.html"
#project_folders = ["/aktuelt/.",
#                   "/arrangementer/.",
#                   "/bibliotek/."]


host = "https://foreninger-dav.uio.no/"
@vortex = Vortex::Connection.new(host,:use_osx_keychain => true)

change_from = '/nyweb'
change_to = ''
logfile = "nmf-vask-log.html"
project_folders = ["/nmf/ny-web/."]

project_folders.each do |project_folder|
  puts
  puts "Project_folder: " + project_folder
  @log += "<h2>" + project_folder + "</h2>\n"
  get_file_content(project_folder, change_from, change_to)
end

write_log(logfile)
