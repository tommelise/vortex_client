
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

def convert_to_json(item)
  resourceType = item.propfind.xpath("//v:resourceType", "v" => "vrtx").first.text
  filename = item.url.path.to_s
  doc = item.content
  file_encoding = doc.to_s.encoding.name
  #  puts "Filename: " + filename + " resourceType: " + resourceType 
  @log1 += "<br>\n Filename: " + filename + " resourceType: " + resourceType + "<br>\n"
  if(doc.to_s.include?('"resourcetype":'))
    puts "" + filename
    @log1 += "JSON-format: " + filename+ "<br>\n"
    @log1 += "Converting:  " + filename + "<br>\n" 
    if doc.encoding.name == "ASCII-8BIT" or content.encoding.name == "US-ASCII"
      binding.pry
      doc = doc.force_encoding("UTF-8")
      doc = Iconv.conv("UTF8", "LATIN1", doc)
      doc = doc.force_encoding("UTF-8")
      #  doc = escapeHTML(doc)
    end
  end
  if doc.to_json.length < 16380
    binding.pry
 #   @vortex.put_string(filename, doc_data.to_json)
 #   @vortex.proppatch(filename,'<v:userSpecifiedCharacterEncoding xmlns:v="vrtx">utf-8</v:userSpecifiedCharacterEncoding>')
  else
    msg = "WARNING! Not converted. String to long (max 16380). Length: " + doc.to_json.length.to_s 
    puts msg
    @log1 += msg + "<br>\n"
  end
end  

# Simple logger
def write_log(logfil, log)
  log=  "<html>\n" +
    "  <head><title>Report</title></head>\n" +
    "  <body>\n" +
    "    <h1>" + Time.now.iso8601 + "<br>\nChangelog - Changed occurances</h1>\n" + 
    log + 
    "  </body>\n" +
    "</html>\n"
  File.open(logfil, 'w') do |f|
    f.write(log)
  end
  puts "\nChangelog written to file: " + logfil
end

if __FILE__ == $0
  host = "https://foreninger-dav.uio.no/"
  @vortex = Vortex::Connection.new(host,:use_osx_keychain => true)
  @log1 =""


  @vortex.find('/url/konv', :recursive => true, :filename=>/\.html$/) do |item|
    puts "Filename: " + item.url.path.to_s + " resourceType: " + item.propfind.xpath("//v:resourceType", "v" => "vrtx").first.text
    puts "encoding: " + item.content.to_s.encoding.name
    convert_to_json(item)
  end

  write_log("encodinglog-url.html",@log1)
end
