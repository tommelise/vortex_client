# -*- coding: utf-8 -*-
require 'rubygems'
require 'vortex_client'
require 'nokogiri'
require 'open-uri'
require 'uri'
require 'pathname'
require 'json'
require 'cgi'
require 'pathname'
include Vortex


def is_a_number?(s)
  s.to_s.match(/\A[+-]?\d+?(\.\d+)?\Z/) == nil ? false : true
end

def format_date(date)
  p=date.split("-")
  return Time.local(p[0],p[1],p[2])
end

def special_chars(str)
  char = {
    ['Å','å','á','à','â','ä','ã','Ã','Ä','Â','À','&aring;','&Aring;'] => 'a',
    ['Æ','æ','é','è','ê','ë','Ë','É','È','Ê','&eacute;','&Aelig;','&aelig;'] => 'e',
    ['í','ì','î','ï','I','Î','Ì','&iacute;'] => 'i',
    ['Ø','ø','ó','ò','ô','ö','õ','Õ','Ö','Ô','Ò','&Oslash;','&oslash;'] => 'o',
    ['ß'] => 'ss',
    ['ú','ù','û','ü','U','Û','Ù'] => 'u',
    ['§'] => '',
    ["--"] => "-" 
  }
  char.each do |ac,rep|
    ac.each do |s|
      str = str.gsub(s, rep)
    end
  end
  return str
end

def unescapeHTML(str)
  char = {
    ['&Aring;']  => 'Å',
    ['&aring;']  => 'å',
    ['&eacute;'] => 'é',
    ['&Aelig;']  => 'Æ',
    ['&aelig;']  => 'æ',
    ['&iacute;'] => 'í',
    ['&Oslash;'] => 'Ø',
    ['&oslash;'] => 'ø',
    ['&nbsp;']   => ' ',
  }
  char.each do |ac,rep|
    ac.each do |s|
      str = str.gsub(s, rep)
    end
  end
  return str
end

# Download pdf to rel_dest_url and return absolute filename
def download_resource(src_url,rel_dest_url,content_type)
  puts "src_url: " + src_url
  begin 
    content = open(src_url).read

    #timeout(15) do # Makes open-uri timeout after 10 seconds.
    #  begin
    #    puts "----------------------"
    #    content = open(src_url).read
    #    puts "----------------------"
    #  rescue
    #    puts "Error: Timeout: " + src_url
    #    # binding.pry
    #    return nil
    #  end
    #end

    basename = Pathname.new(src_url).basename.to_s.gsub(/\..*/,'').gsub(" ","-")
    vortex_url = rel_dest_url + basename + "." + content_type
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
exit
end

def get_entire_list(url,rel_dest_url)
  html = open(url).read
  html = html.gsub("&nbsp;"," ").gsub("\n"," ").gsub("\r"," ") #Removes non-line-break and dos-line-break
  html = CGI.unescapeHTML(html) #remove HTML-encoding
  index = Nokogiri::HTML.parse(html) 
  index.encoding = 'utf-8'
  link_list=Array.new
  link_list = get_link_list(link_list,index.css('td[width="80%"]'))
  link_list.each do |link|
    puts "link: " + link
    get_file_content(url,rel_dest_url,link)
    puts "Number of links: " + link_list.size.to_s
  end
end

def get_link_list(link_list,html)
  html.css("h1").each { |node| node.remove }
 # html.css("h2").each { |node| node.remove }
  list = unescapeHTML(html.inner_html)
  list = list.gsub(/\s{2,}/," ") #removes 2 or more space from string
  list = list.gsub("<li>","").gsub("</li>","").gsub("<ul>","").gsub("</ul>","") 
  list = list.gsub("<br>","\n").gsub("<p>","\n").gsub("</p>","\n").gsub("/a><a","/a>\n<a").strip
  list = list.split("\n")
  link_list=link_list + list
  link_list.delete_if{|element| element == "" || element == " " } # delete empty elements in list
  link_list.delete_if{|element| not element.include?("<a")}       # delete non-link-elements in list
#  link_list.delete_if{|element| element.include?("<h2>") }       # delete h2-elements in list
  return link_list
end


def get_full_link(url,href)
  if(not(href =~ /^http\:/) and href =~ /\// and url =~ /^http\:/) #Finds fullpath
    uri=URI::parse(url)
    base_array = uri.path.split("/")
    base_array.pop
    base_array.shift
    link_array = href.split("/")    
    link_array.each do |element|
      if element.eql?("..")
        link_array.shift
        base_array.pop
      end
    end 
    url_array = base_array+link_array
    href=uri.scheme+"://"+uri.host+"/"+url_array.join("/")
    return href
  end
end


def get_file_content(url,rel_dest_url,link)
  if link.include?("<a")
    a = Nokogiri::HTML.parse(link) 
    href = a.css("a").attr("href")
    source =  get_full_link(url,href.to_s)
    puts "source: " + source
    if(source)
      content, introduction, published_date, title = check_source(source.to_s,title,rel_dest_url)  
    end
  end
  if title==nil || title == ""
    title = a.css("a").inner_html.to_s
  end
#puts "title: " + title
#puts "introduction: " + introduction
#puts "content: " + content.to_s
  if title!=nil && title!="" && content!=nil && content!=""
    filename = File.basename(source)
#    publish_article(content,introduction,rel_dest_url,title,published_date,filename)
  else
    puts "Something amiss with this item"
  end
  puts
end


def check_source(source,title,rel_dest_url)
  if (source =~/\/$/) #oldlink ends with "/" (It's probably a folder with an index-file)
    source=source + "index.html"
  elsif source.include?(".html")
    content, introduction, published_date, title = scrape_html(source,title)
  elsif (source.include?(".pdf"))
    download_resource(source,rel_dest_url,"pdf")
    puts "pdf - downloading ..."
    @log = @log + "pdf - downloading ...\n"
  else
    puts "WARNING: Invalid: " +source
    @log = @log + "WARNING: Invalid: " + source + "<br/>\n"
  end
  return content, introduction, published_date, title
end


def scrape_html(url,title)
  published_date = Time.now
  html = open(url).read
  html = html.to_s.gsub("&nbsp;"," ").gsub("\n","").gsub("\r","").gsub(/"/,"'") #Removes non-break-space and dos-line-break
  doc = Nokogiri::HTML.parse(html)
  doc.encoding = 'utf-8' 
  content=""  
  doc.css("meta").each do |meta|
    if meta.attr("name").eql?("dato.opprettet")
      published_date = format_date(meta.attr("content"))
      puts "published_date: " + published_date.to_s
    end
  end
  title = doc.css("head title").first.inner_html
  introduction = doc.css('table[width="70%"] table[width="100%"] td').inner_html
  introduction = introduction.gsub(/<\/?h[^>]*>/,"").strip #removes h1-,h2-,h3- and hr-formatting
  introduction = introduction.gsub(/\s{2,}/,' ').gsub(/\s{2,}/,' ') #removes two or more adherent spaces
  doc.css('table[width="70%"] table[width="100%"]').remove
  content =  doc.css('table[width="70%"] td').first.to_s

#  binding.pry
  # content = content.gsub(/\<!--.*\-->/,'').gsub(/\<!--\n.*\-->/,'')       #removes comments
  content = content.gsub(/\s{2,}/,' ').gsub(/\s{2,}/,' ') #removes two or more adherent spaces
  content = content.gsub(/style=\"[^\"]*\"/,"")  #removes inline style
  content = content.gsub(/<\/?font[^>]*>/,"") #removes font-formatting
  content = content.gsub(/"/,"'").gsub("\n","").gsub("\r","").gsub("ó","o")
#  content = Iconv.conv("ISO-8859-1", "UTF-8",content).to_s  
  if !(content == "")
    return content, introduction, published_date, title
  else
    return nil
  end
end


def scrape_img_url(url,tag)
  puts "url:" +url
  doc = Nokogiri::HTML.parse(open(url))
  if(doc.css(tag).size > 0)
    image_src = doc.css(tag).attr("src").to_s
    image_src = Pathname.new(url).parent + image_src
    if !image_src.to_s.include?("http://") && url.to_s.include?("http://")
      uri = URI.parse(url)
      image_src = uri.scheme + "://" + uri.host + image_src
    end
    return image_src
  end
  return nil
end


def create_article_listing(new_url,name)
  if(not(@vortex.exists?(new_url)))
    collection = Collection.new(:url => new_url, :title => name)
    path = @vortex.create(collection)
    puts "Creating folder: " + path
    @log = @log + "Creating folder: " + path + "<br/>\n"
  end
  props = '<v:collection-type xmlns:v="vrtx">article-listing</v:collection-type>' +
    '<v:resourceType xmlns:v="vrtx">article-listing</v:resourceType>'+
    '<v:userTitle xmlns:v="vrtx">' + name.to_s +  '</v:userTitle>'
  begin
    @vortex.proppatch(new_url, props )
  rescue
    puts "Warning: problems patching folder: " + new_url
    @log = @log + "Warning: problems patching folder: " + new_url + "<br/>\n"
  end
end


def publish_article(content,introduction,rel_dest_url,title,published_date,filename)
  content=content.gsub(/\<!--.*\-->/,'')
  content=content.gsub(/\s{2,}/,' ')
  content=content.gsub(/"/,"'")
  content=content.gsub(/style=\"[^\"]*\"/,"")
  @vortex.cd(rel_dest_url)
  url = rel_dest_url + "/" + filename
  article  = Vortex::StructuredArticle.new(:title => title,
                                           :introduction => introduction,
                                           :body => content,
                                           :publishedDate => published_date,
                                           :author => "",
                                           :url => url)
  path = @vortex.publish(article)

  puts "published " + path 
  puts
#exit 
end


# Simple logger
def write_log(logfil)
  @log=  "<html>\n" +
    "  <head><title>STK-articles</title></head>\n" +
    "  <body>\n" +
    "    <h1>" + Time.now.iso8601 + "<br>\nChangelog - STK-articles</h1>\n" + 
    @log + 
    "  </body>\n" +
    "</html>\n"
  File.open(logfil, 'a') do |f|
    f.write(@log)
  end
  puts "\nChangelog written to file: " + logfil
end
 
logfile = "stk-konverteringslog.html"
url = "http://www.stk.uio.no/formidling/alfabetisk.html"
dest_url = "https://nyweb5-dav.uio.no/konv/"
rel_dest_url = "/konv/formidling"

@log =""
@vortex = Vortex::Connection.new(dest_url,:use_osx_keychain => true)

#create_article_listing("https://nyweb5-dav.uio.no/konv/formidling","formidling")
get_entire_list(url,rel_dest_url)
#write_log(logfile)
