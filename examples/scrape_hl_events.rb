# -*- coding: utf-8 -*-
# related_content
#
# Author: Lise Hamre


require 'rubygems'
require 'vortex_client'
require 'open-uri'
require 'uri'
require 'net/https'
require 'ruby-debug'

def http_content_type(url)
  uri = URI.parse(url)
  http = Net::HTTP.new(uri.host, uri.port)
  request = Net::HTTP::Get.new(uri.request_uri)
  request["User-Agent"] = "My Ruby Script"
  request["Accept"] = "*/*"
  response = http.request(request)
  return response['content-type']
end

def get_location(doc,date)
  time = ""
  location = ""
  doc.css(".info .date").each do |info|
    if info.text.include?("Tid:")
      time = info.text.gsub("Tid: ","")
    else
      location = escape_html(info.text)
    end
  end
  date= "20" + date + " " + time
  return location,date
end 

def scrape_images(doc)
  images = []
  i = 0
  doc.css(".imageSeriesImage").each do |item|
    url = item.attr("src").gsub(/\?.*$/,"")
    caption = doc.css(".imageText")[i].text
    images << { :url => url, :caption => caption }
    i = i + 1
  end
  return images
end

# Download graphic to dest_path and return absolute filename
def download_image(src_url,dest_path)
  content_type = http_content_type(src_url)
  content_type = content_type.gsub("image/", "")
  content_type = content_type.gsub("pjpeg","jpg")
  content_type = content_type.gsub("jpeg","jpg")
  vortex_url = download_resource(src_url,dest_path,content_type)
  return vortex_url
end

# Download pdf to dest_path and return absolute filename
def download_resource(src_url,dest_path,content_type)
  begin 
    content = open(src_url).read
    basename = Pathname.new(src_url).basename.to_s.gsub(/\..*/,'')
    vortex_url = dest_path + basename + "." + content_type
    vortex_url = vortex_url.downcase
    begin
      @vortex.put_string(vortex_url, content)
      puts "Copying resource: " + src_url + " => " + vortex_url
      @log = @log + "Copying resource: " + src_url + " => " + vortex_url + "<br>\n"
    rescue Exception => e
      puts e.message
      pp e.backtrace.inspect
      puts "vortex_url: " + vortex_url
      exit
    end
    return vortex_url
  rescue
    puts "WARNING could not open file " + src_url
    @log = @log +  "WARNING could not open file " + src_url + "<br>\n"
    return nil
  end
end

def get_list(url,rel_dest_url)
  html = open(url).read
  html = html.gsub("&nbsp;"," ").gsub("\n"," ").gsub("\r"," ") #Removes non-line-break and dos-line-break
  #  html = CGI.unescapeHTML(html) #remove HTML-encoding
  doc = Nokogiri::HTML.parse(html) 
  doc.encoding = 'utf-8'
  #  doc.css(".arrangement .title a").each do |arr|
  doc.css(".arrangement").each do |arr|
    date = arr.css(".date").inner_html
    date = date[0..7].split("/").reverse.join("-")
    event = arr.css(".title a").first
    event_title = escape_html(event.text.to_s)
    href = event.attr("href").to_s
    get_event(rel_dest_url,href,event_title,date)
  end
  #    exit
end  

def escape_html(str)
  new_str = str.gsub("&#xD;","")        #remove line break
  #  new_str = new_str.gsub(/'/, "\"") # Fnutter gir "not valid xml error"
  new_str = new_str.gsub("&nbsp;", " ") # &nbsp; gir også "not valid xml error"
  new_str = new_str.gsub("", "-") # Tankestrek til minustegn
  new_str = new_str.gsub("","'")  # Fnutt
  new_str = new_str.gsub("","'")  # Fnutt
  new_str = new_str.gsub("","'")  # Fnutt
  new_str = new_str.gsub("","'")  # Fnutt
  return new_str
end

def get_event(rel_dest_url,event_url,event_title,date)
  introduction=""
  basename = File.basename(event_url)
  puts "\nEvent title: " + event_title + "\nEvent-url: " + event_url
  @log = @log + "<br>\nEvent title: " + event_title + "<br>\nEvent-url: " + event_url + "<br>\n"
  html = open(event_url).read
  #Removes non-line-break and dos-line-break
  html = html.gsub("&nbsp;"," ").gsub("\n"," ").gsub("\r"," ").gsub("\t","").gsub(/\s{2,}/," ")
  doc = Nokogiri::HTML.parse(html) 
  doc.encoding = 'utf-8'
  location, date_time = get_location(doc,date)
  images=[]
  content = ""
  if doc.css(".abstract") && doc.css(".abstract").first
    introduction = doc.css(".abstract").first.inner_html
    introduction = escape_html(introduction)
  end
  doc.css(".program").each do |prog|
    prog.css("table").each do |table|
      images = scrape_images(doc)
      table.remove
    end
    prog.css("img").each do |img|
      url = img.attr("src").gsub(/\?.*$/,"")
      images << { :url => url }
      img.remove
    end
    links = Array.new
    prog.css("a").each do |a|
      link = a.attr("href").strip
      if URI.parse(event_url) == URI.parse(link) && link.include?(".pdf")
        new_pdf_src = download_resource(link, rel_dest_url, "pdf")
        if new_pdf_src
          links << {:old => link, :new => new_pdf_src}
        end
      end
    end
    content = prog.inner_html
    content = content.gsub(/style=\"[^\"]*\"/,"").gsub("<span >","<p>").gsub("</span>","<\/p>")
    content = escape_html(content)
    if links.first
      links.each do |i|
        content = content.gsub(i[:old],i[:new])
      end
    end
  end
  new_url = rel_dest_url + basename + ".html"  
  publish_event(new_url, rel_dest_url, event_title, introduction, content, images, date_time, location)
end

def publish_event(url, rel_dest_url,event_title, introduction, content, images, date_time, location)
  event = {
    "resourcetype" => "structured-event",
    "properties" =>    {
      "content" => content,
      "title" => event_title,
      "introduction" => introduction,
      "start-date" => date_time,
      "location" => location,
      "publishedDate" => Time.now
    }
  }
  if(images and images.first)then
    image = images.first
    if image[:caption]
      event["properties"]["caption"] = image[:caption]
    end
    if image[:url]
      image_src = image[:url]
      new_image_src = download_image(image_src, rel_dest_url)
      puts "image_src: " + new_image_src
      event["properties"]["picture"] = new_image_src
    end
    images_html = add_additional_images(images,rel_dest_url)
    if images_html
      event["properties"]["content"] += images_html
    end
  end
  @vortex.put_string(url, event.to_json)
  props = '<v:publish-date xmlns:v="vrtx">' + Time.now.httpdate.to_s +  '</v:publish-date>'
  begin
    @vortex.proppatch(url, props )
  rescue
    puts "Warning: problems patching folder: " + url
    @log = @log + "Warning: problems patching file: " + url + "<br/>\n"
  end
  puts "Published: " + url + "\n\n"
  @log = @log + "Published: " + url + "<br/>\n<br/>\n"
end

def add_additional_images(images,rel_dest_url)
  images_html = ""
  if(images and images.size > 1)then
    images[1..images.size].each do |image|
      if image[:url]
        new_image_src = download_image(image[:url], rel_dest_url)
        image_html = <<EOF
        <p>
          <div class="vrtx-introduction-image" style="width: 300px; ">
              <img src="#{image[:url]}" style="width: 300px;" />
            </a>
            <div class="vrtx-imagetext">
              <div class="vrtx-imagedescription">
                #{image[:caption]}
              </div>
            </div>
          </div>
        </p>
EOF
        return images_html = images_html + image_html
      end
    end
  end
end

# Simple logger
def write_log(logfil)
  @log=  "<html>\n" +
    "  <head><title>Events</title></head>\n" +
    "  <body>\n" +
    "    <h1>" + Time.now.iso8601 + "<br>\nChangelog - Events</h1>\n" + 
    @log + 
    "  </body>\n" +
    "</html>\n"
  File.open(logfil, 'w') do |f|
    f.write(@log)
  end
  puts "\nChangelog written to file: " + logfil
end


@log = ""
logfil = "hl-event-log.html"
host = "https://nyweb4-dav.uio.no/"
@vortex = Vortex::Connection.new(host,:use_osx_keychain => true)

(2006..2010).each do |year|
  url = "http://www.hlsenteret.no/Arrangementer/Arrangementer_pa_HL-senteret_i_"+ year.to_s
  rel_dest_url = "/arrangementer/" + year.to_s + "/"
  get_list(url,rel_dest_url)
end

write_log(logfil)

