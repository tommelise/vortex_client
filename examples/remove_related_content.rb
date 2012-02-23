# -*- coding: iso-8859-1 -*-
# related_content
#
# Author: Lise Hamre

require 'rubygems'
require 'vortex_client'
require 'json'
require 'nokogiri'
require 'pp'
require 'uri'
require 'pathname'


#TODO: skrive til logfil

class Remove_related_content

  def initialize(host)
    @vortex = Vortex::Connection.new(host,:use_osx_keychain => true)
  end

  def rel_content(path)
    doc = @vortex.get(path)
          puts "doc: " + doc.to_s
    data = JSON.parse(doc)
   if(data["properties"]["related-content"])
      return data["properties"]["related-content"]
   else
     return []
    end
  end

  def remove_if_empty(tag,doc)
    doc.xpath(tag).each do |item|
      if (item.text.strip =="") 
        item.remove 
      end
    end
    return doc
  end
  
  def remove_rel_content(path,host)
    log = ""
   
    @vortex.find(path,:recursive => true,:filename=>/\.html$/) do |item|
      puts item.uri.to_s
      log += "File: " + item.uri.to_s + "<br\/>\n"
      data = nil
      begin
        data = JSON.parse(item.content)
      rescue
        puts "Warning. Bad document. Not json:" + item.uri.to_s
        log = log + "Warning. Bad document. Not json:" + item.uri.to_s + "<br\/>\n<br\/>\n"
      end
      if(data)
        if data["properties"]["related-content"] 
          doc=data["properties"]["related-content"]
          doc = doc.gsub("&nbsp;"," ").gsub("\t","")
          html = Nokogiri::HTML.parse(doc)
  #        html.xpath(".//p/b").each do |title|
  #          element = title.parent.next_sibling
  #          while(element != nil and element.class == Nokogiri::XML::Text)
  #            element = element.next_sibling
  #          end
  #          element.xpath(".//li/a").each do |li|
  #            href = li.attribute("href").value
  #            if (href.include?(path.chop) || href.include?("http://www.hlsenteret.no")   || (not href  =~ /^http\:/ ))
  #              puts "remove: " + href
  #              log += "remove: " + href +"<br\/>\n"
  #              li.remove
  #            else
  #              puts "keep: " + href 
  #              log += "keep: " + href +"<br\/>\n"
  #            end
  #          end
  #          html = remove_if_empty(".//li",html)
  #          html = remove_if_empty(".//ul",html)
  #          if element.xpath(".//li/a").size < 1
  #            title.remove
  #            puts "REMOVE: " + title
  #            log += "REMOVE: " + title +"<br\/>\n"
  #          else 
  #            puts "KEEP: " + title
  #            log += "KEEP: " + title +"<br\/>\n"
  #          end
  #          html = remove_if_empty(".//p",html)
  #        end
  #        html = html.inner_html.gsub("\t","").gsub("\n","").gsub("\r","").gsub(/\s{2,}/," ").strip
  #        puts
  #        log += "<br\/>\n"
# #        puts "html: '" + html.to_s + "'"
  #      end
        html = html.to_s.gsub("<html>","").gsub("</html>","").gsub("<body>","").gsub("</body>","")
#        if !html.to_s.include?("${include:tags")
#          uri = URI.parse(item.uri.to_s)
#          tag_folder = uri.path
#          tag_folder = File.dirname(tag_folder)
#          html="<p>${include:tags scope=["+ tag_folder +"]}<\/p>" + html
#        end
          if html.to_s.include?("<h2>S&oslash;k i Kunnskapsbasen</h2>")
            html = html.gsub("<h2>S&oslash;k i Kunnskapsbasen</h2>","")
          end
          if html.to_s.include?("<p>${include:search-form}</p>")
            html = html.gsub("<p>${include:search-form}</p>","")
          end
          data["properties"]["related-content"] = html.strip
#          data["properties"]["related-content"] = ""
          item.content = data.to_json
        end
      end
    end
    return log
  end
  
  # Simple logger
  def write_log(logfil,log)
    log=  "<html>\n" +
      "  <head><title>Remove related content</title></head>\n" +
      "  <body>\n" +
      "    <h1>" + Time.now.iso8601 + "<br>\nChangelog - nye personpresentasjoner</h1>\n" + 
      log + 
      "  </body>\n" +
      "</html>\n"
    File.open(logfil, 'w') do |f|
      f.write(log)
    end
    puts "\nChangelog written to file: " + logfil
  end

end

host = "https://www-dav.vortex-demo.uio.no"
rel_path = "/personer/lise/."

#host = "https://nyweb4-dav.uio.no/"
#rel_path = "/kunnskapsbasen/."
#rel_path = "/publikasjoner/."

remove_related_content = Remove_related_content.new(host)

log = remove_related_content.remove_rel_content(rel_path,host)
remove_related_content.write_log("remove-related-content.html",log)
