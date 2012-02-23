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

# Download graphic to dest_path and return absolute filename
def download_image(url,src_url,dest_path)
  if !src_url.include?("http://")
    src_url = "http://" + URI.parse(url).host + src_url
  end
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

def add_additional_images(url,images,rel_dest_url)
  images_html = ""
  if(images and images.size > 1)then
    images[1..images.size].each do |image|
      if image[:new_src]
        new_image_src = download_image(url,image[:new_src], rel_dest_url)
        image_html = <<EOF
        <p>
          <div class="vrtx-introduction-image" style="width: 300px; ">
              <img src="#{image[:new_src]}" style="width: 300px;" />
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

def get_list(url,rel_dest_url)
  html = open(url).read
  html = html.gsub("&nbsp;"," ").gsub("\n"," ").gsub("\r"," ") #Removes non-line-break and dos-line-break
  doc = Nokogiri::HTML.parse(html) 
  doc.encoding = 'utf-8'
  doc.css(".article").each do |art|
    article = art.css(".title a").first
    if article
      article_title = escape_html(article.text.to_s)
      href = article.attr("href").to_s
      get_article(rel_dest_url,href,article_title)
    end
  end
  #    exit
end  

def scrape_images(url,doc,rel_dest_url)
  images = []
  i = 0
  doc.css(".imageSeriesImage").each do |item|
    image_src = item.attr("src").gsub(/\?.*$/,"")
    caption = doc.css(".imageText")[i].text
    new_image_src = download_image(url,image_src, rel_dest_url)
    images << { :old_src => image_src,:new_src => new_image_src, :caption => caption }
    i = i + 1
  end
  return images
end

def scrape_img(url,doc,rel_dest_url)
  images=[]
  doc.css("img").each do |image|
    image_src = image.attr("src").gsub(/\?.*$/,"")
    puts "image_src: "+ image_src
    @log = @log + "image_src: "+ image_src + "<br>\n"
    new_image_src = download_image(url,image_src, rel_dest_url)
    images << {:old_src => image_src, :new_src => new_image_src}
  end
  return images
end

def scrape_links(doc,rel_dest_url,article_url,content_type)
  hl_links = Array.new
  hl_links << {:old_src => "http://www.hlsenteret.no/Nyheter/", :new_src => "/aktuelt/"}
  hl_links << {:old_src => "http://www.hlsenteret.no/Arrangementer/Arrangementer_pa_HL-senteret_i_", :new_src => "/arrangementer/"}
  links = Array.new
  host = URI.parse(article_url).host
  doc.css("a").each do |a|
    link = a.attr("href").strip
    puts "link: " + link
    @log = @log + "link: " + link + "<br>\n"
    if !link.include?("http://")
      link = "http://" + host + link
    end
    if !link.include?("mailto") && !link.include?("javascript:")
      if host == URI.parse(link).host && link.include?("." + content_type)
        new_link = download_resource(link, rel_dest_url, content_type)
      end
    end
    if link.include?("http://www.hlsenteret.no/Nyheter/") || link.include?("http://www.hlsenteret.no/Arrangementer/")
      new_link = swap_content(link,hl_links) + ".html"
    end
    if new_link
      links << {:old_src => link, :new_src => new_link}
    end
  end
  return links
end

def swap_content(doc,swap_array)
  if swap_array.first
    swap_array.each do |i|
      doc = doc.gsub(i[:old_src],i[:new_src])
    end
  end
  return doc
end

def get_rel_content(doc,article_url,rel_dest_url)
  rel_content = ""
  doc.css(".relatedItemsContainer .file").each do |file|
    rel_images = scrape_img(article_url,file,rel_dest_url)
    rel_links = scrape_links(file,rel_dest_url,article_url,"pdf")
    rel_content = file.inner_html
    rel_content = swap_content(rel_content,rel_images)
    rel_content = swap_content(rel_content,rel_links)
  end
  return rel_content
end

def get_article(rel_dest_url,article_url,article_title)
  introduction=""
  images =[]
  rel_content = ""
  basename = File.basename(article_url)
  puts "\nArticle title: " + article_title + "\nArticle-url: " + article_url
  @log = @log + "<br>\nArticle title: " + article_title + "<br>\nArticle-url: " + article_url + "<br>\n"
  html = open(article_url).read
  #Removes non-line-break and dos-line-break
  html = html.gsub("&nbsp;"," ").gsub("\n"," ").gsub("\r"," ").gsub("\t","").gsub(/\s{2,}/," ")
  doc = Nokogiri::HTML.parse(html) 
  doc.encoding = 'utf-8'
  content = ""
  if doc.css(".abstract") && doc.css(".abstract").first
    introduction = doc.css(".abstract").first.inner_html
    introduction = escape_html(introduction)
  end
  doc.css(".article").each do |article|
    article.css("table").each do |table|
      images = scrape_images(article_url,doc,rel_dest_url)
    end
  end
  doc.css(".text").each do |text|
    text_images = scrape_img(article_url,text,rel_dest_url) 
    links = scrape_links(text,rel_dest_url,article_url,"pdf")
    content = text.inner_html
    content = content.gsub(/style=\"[^\"]*\"/,"").gsub("<span >","<p>").gsub("</span>","<\/p>")
    content = escape_html(content)
    content = swap_content(content,links) 
    content = swap_content(content,text_images) 
  end
  rel_content = get_rel_content(doc,article_url,rel_dest_url)
  new_url = rel_dest_url + basename + ".html"  
  publish_article(new_url, rel_dest_url, article_title, introduction, content, images, rel_content)
end

def publish_article(url, rel_dest_url, article_title, introduction, content, images, rel_content)
  article = {
    "resourcetype" => "structured-article",
    "properties" =>    {
      "content" => content,
      "title" => article_title,
      "introduction" => introduction,
      "hideAdditionalContent" => "false",
      "publishedDate" => Time.now
   }
  }
  if rel_content
    # article["properties"]["related-content"] = rel_content
    article["properties"]["content"] += rel_content
  end
  if(images and images.first)then
    image = images.first
    if image[:caption]
      article["properties"]["caption"] = image[:caption]
    end
    if image[:new_src]
      article["properties"]["picture"] = image[:new_src]
    end
    images_html = add_additional_images(url,images,rel_dest_url)
    if images_html
      article["properties"]["content"] += images_html
    end
  end
  @vortex.put_string(url, article.to_json)
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

# Simple logger
def write_log(logfil)
  @log=  "<html>\n" +
    "  <head><title>Articles</title></head>\n" +
    "  <body>\n" +
    "    <h1>" + Time.now.iso8601 + "<br>\nChangelog - Articles</h1>\n" + 
    @log + 
    "  </body>\n" +
    "</html>\n"
  File.open(logfil, 'w') do |f|
    f.write(@log)
  end
  puts "\nChangelog written to file: " + logfil
end

@log = ""
logfil = "hl-news-log.html"
host = "https://nyweb4-dav.uio.no/"
@vortex = Vortex::Connection.new(host,:use_osx_keychain => true)


(2006..2007).each do |year|
  url = "http://www.hlsenteret.no/Mapper/Nyheter_fra_"+ year.to_s
  rel_dest_url = "/aktuelt/" + year.to_s + "/"
  get_list(url,rel_dest_url)
end

url = "http://www.hlsenteret.no/Nyheter"
rel_dest_url = "/aktuelt/"
get_list(url,rel_dest_url)


write_log(logfil)


