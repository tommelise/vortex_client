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
require "iconv"


class Net::DAV::Item
  def vortex_prop(name)
    return self.propfind().xpath('//v:' + name, "v" => 'vrtx')
  end
end

def add_property(doc_data, name, value)
  if(value and value != "")
    doc_data["properties"][name] = value
  end
   return doc_data
end

def json_doc(item,type)
  doc = item.content
#  latin1 = Iconv.new("UTF8//TRANSLIT//IGNORE", "LATIN1")
#  doc = latin1.iconv(doc)
  if doc.encoding.name == "ASCII-8BIT" or doc.encoding.name == "US-ASCII"
    doc = doc.force_encoding("UTF-8")
    doc = Iconv.conv("UTF8", "LATIN1", doc)
    doc = doc.force_encoding("UTF-8")
  end


  doc = Nokogiri::HTML(doc)
  title = item.vortex_prop('userTitle').text
  if(!title or title == "")
    title = item.vortex_prop('htmlTitle').text
  end
  if((!title or title == "") and doc.css("h1").first )
    title = doc.css("h1").first.text
  end
  if(!title)
    title = ""
  end
  if doc.css("h1").first
    doc.css("h1").first.remove
  end
  content = doc.css("body").inner_html
  picture = item.vortex_prop('picture').text
  if item.vortex_prop('introduction')
    introduction =  item.vortex_prop('introduction').inner_html
    introduction = HTMLEntities.new.decode introduction
  end
  tags = []
  item.propfind.xpath('//v:tags//vrtx:value', {"vrtx" => "http://vortikal.org/xml-value-list", "v" => 'vrtx'}).each do |element|
    tags << element.text
  end
  caption = item.vortex_prop("caption").inner_html.strip
  doc_data =  {
    "resourcetype" => "structured-" + type,
    "properties"   =>{
      "showAdditionalContent"=>"false", 
      #     "hideAdditionalContent"=>"false",
      "title"      => title, 
      "content"    => content
    }
  }
  if tags.size > 0
    doc_data = add_property(doc_data, 'tags', tags)
  end
  doc_data = add_property(doc_data, 'picture', picture)
  doc_data = add_property(doc_data, 'caption', caption)
  doc_data = add_property(doc_data, 'introduction', introduction)
  return doc_data
end

def event_doc(item,resourceType)
  start_date = ""
  end_date = ""
  doc_data  = json_doc(item,resourceType)
  start_date = item.propfind.xpath("//v:start-date", "v" => "vrtx").text 
  if start_date != ""
    start_date = Time.parse(start_date).strftime("%Y-%m-%d %H:%M:%S")
  end
  end_date   = item.propfind.xpath("//v:end-date", "v" => "vrtx").text
  if end_date !=""
    end_date   = Time.parse(end_date).strftime("%Y-%m-%d %H:%M:%S")
  end
  location   = item.propfind.xpath("//v:location", "v" => "vrtx").text
  mapurl     = item.propfind.xpath("//v:mapurl", "v" => "vrtx").text
  doc_data = add_property(doc_data, 'start-date', start_date)
  doc_data = add_property(doc_data, 'end-date', end_date)
  doc_data = add_property(doc_data, 'location', location)
  doc_data = add_property(doc_data, 'mapurl', mapurl)
  return doc_data
end

def article_doc(item,resourceType)
  doc_data = json_doc(item,resourceType)
  authors = []
  item.propfind.xpath('//v:authors//vrtx:value', {"vrtx" => "http://vortikal.org/xml-value-list", "v" => 'vrtx'}).each do |element|
    authors << element.text
  end
  doc_data = add_property(doc_data, "author", authors)
  return doc_data
end

def convert_to_json(item)
  resourceType = item.propfind.xpath("//v:resourceType", "v" => "vrtx").first.text
  filename = item.url.path.to_s
  file_encoding = item.content.to_s.encoding.name
  #  puts "Filename: " + filename + " resourceType: " + resourceType 
  @log1 += "<br>\n Filename: " + filename + " resourceType: " + resourceType + "<br>\n"
  if(item.content.to_s.include?('"resourcetype":'))
    puts "Not converted. JSON-format: " + filename
    @log1 += "Not converted. JSON-format: " + filename+ "<br>\n"
  elsif (resourceType != "article" and resourceType != "event" and resourceType != "xhtml10trans" and resourceType != "html")
    puts "Not converted. Unknown format: " + filename
    @log1 += "Not converted. Unknown format: " + filename + "<br>\n"
  elsif filename.include?("_orig.html") 
    puts "Not converted. Backup-file: " + filename
    @log1 += "Not converted. Backup-file: " + filename + "<br>\n"
  elsif filename == "adresse.html"
    puts "Not converted. File to be included. Cannot be json: " + filename
    @log1 += "Not converted. File to be included. Cannot be json: " + filename + "<br>\n"
  elsif filename.include?("infobox.html")
    puts "Not converted. File to be included. Cannot be json: " + filename
    @log1 += "Not converted. File to be included. Cannot be json: " + filename + "<br>\n"
  elsif (resourceType == "xhtml10trans" or resourceType == "html" or resourceType == "article" or resourceType == "event")
    if (resourceType == "xhtml10trans" or resourceType == "html" or resourceType == "article" )
      doc_data = article_doc(item,"article")
    elsif(resourceType == "event")
      doc_data = event_doc(item,"event")
    end
    if(not filename.include?("_orig.html"))
      filename_new = filename.sub(/\.html$/,'_orig.html')
      if(@vortex.exists?(filename_new))
        puts "File exists: " + filename_new
      else
        @vortex.copy(filename, filename_new)
        puts "Copying:     " + filename_new
        @log1 += "Copying:     " + filename_new + "<br>\n"
        puts "Converting:  " + filename  
        @log1 += "Converting:  " + filename + "<br>\n" 
      end
      if doc_data.to_json.length < 16380
#       puts "Output encoding: " + doc_data.to_json.to_s.encoding.name
#       puts "Valid encoding: " + doc_data.to_json.to_s.valid_encoding?.to_s
# binding.pry
        @vortex.put_string(filename, doc_data.to_json)
        @vortex.proppatch(filename,'<v:userSpecifiedCharacterEncoding xmlns:v="vrtx">utf-8</v:userSpecifiedCharacterEncoding>')
      else
        msg = "WARNING! Not converted. String to long (max 16380). Length: " + doc_data.to_json.length.to_s 
        puts msg
        @log2 += "Filename: " + filename + " resourceType: " + resourceType + "<br>\n"
        @log1 += msg + "<br>\n" 
        @log2 += msg + "<br>\n"
      end
    end  
  end
end

# Simple logger
def write_log(logfil, log)
  log_data =  {
    "resourcetype" => "structured-article",
    "properties"   =>{
      "showAdditionalContent"=>"false", 
      "title"      => Time.now.iso8601 + "<br>\nChangelog - Changed occurances</h1>\n", 
      "content"    => log
    }
  }
  @vortex.put_string(logfil, log_data.to_json)
  @vortex.proppatch(logfil,'<v:userSpecifiedCharacterEncoding xmlns:v="vrtx">utf-8</v:userSpecifiedCharacterEncoding>')
  puts "\nChangelog written to file: " + logfil
end

if __FILE__ == $0
  host = "https://foreninger-dav.uio.no/"
  @vortex = Vortex::Connection.new(host,:use_osx_keychain => true)
  @log1 =""
  @log2 =""

host = '/url/konv/news/'
logfile = host + 'konverteringslog-legxv.html'
error_logfile = host + 'konverteringslog-encoding-error-legxv.html'

  @vortex.find(host, :recursive => true, :filename=>/\.html$/) do |item|
    puts "Filename: " + item.url.path.to_s + " resourceType: " + item.propfind.xpath("//v:resourceType", "v" => "vrtx").first.text
    puts "Original encoding: " + item.content.to_s.encoding.name
    if !item.url.to_s.match(/\/gammel\/|\/gammel-2011\/|\/old-web-jan-2008\/|\/ikke-i-bruk\/|\/gamle-websider\/|\/arkiv\//) 
      convert_to_json(item)
    end
  end

  write_log(logfile,@log1)
  write_log(error_logfile,@log2)
end
