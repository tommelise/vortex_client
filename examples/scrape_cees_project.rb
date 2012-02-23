# -*- coding: utf-8 -*-
require 'rubygems'
require 'vortex_client'
require 'nokogiri'
require 'open-uri'
require 'uri'
require 'pry'
require "net/http"
require 'json'
require 'cgi'
require 'iconv'
require 'pathname'
require 'mechanize'
require 'ruby-debug'
require 'ldap'
include Vortex

# Todo
#-prosjekt-periode?
#-logg


def get_reference_list(url) # Makes reference list from stafflist with presentations.
  html = open(url).read
  doc = Nokogiri::HTML.parse(html) 
  doc.encoding = 'utf-8'
  ref_list = Array.new 
  doc.css("td p a").each do |item|
    ref_list << { :name => item.inner_html.to_s, :presentation_url => item.attr("href").to_s}
  end
  return ref_list
end


def special_chars(str)
  char = {
    ['å','á','à','â','ä','ã','&aring;'] => 'a',
    ['æ','é','è','ê','ë','&eacute;','&aelig;'] => 'e',
    ['í','ì','î','ï','&iacute;'] => 'i',
    ['ø','ó','ò','ô','ö','õ','&oslash;'] => 'o',
    ['ś'] => 's',
    ['ł'] => 'l',
    ['ß'] => 'ss',
    ['ú','ù','û','ü'] => 'u',
    ["--"] => "-" 
  }
  char.each do |ac,rep|
    ac.each do |s|
      str = str.gsub(s, rep)
    end
  end
  return str
end


def get_user(full_name)
  if(full_name =~ /,/)then
    name = full_name.gsub(/\(.*\)/,'').gsub(/\s{2,}/,' ')
    name_array = name.split(",")
    realname = name_array[1].strip + " " + name_array[0].strip
    realname = realname.gsub("ś","s").gsub("Ż","Z").gsub("Ś","S").gsub("ń","n").gsub("ł","l")
  end
  ldap_user_id = ldap_uid(realname)
  if (ldap_user_id) && realname !="Merethe Andersen" && realname != "Stine Dreyer" && realname != "Marit Maanum Simonsen" && realname != "Jon Olav Vik"
    new_user_id = ldap_user_id
    ldap_name = ldap_realname(ldap_user_id)
    if realname != ldap_name 
      puts "WARNING: Possible mismatch. Name in LDAP (#{ldap_name}) different from scraped name (#{realname}) \n"
      @log = @log + "WARNING: Possible mismatch. Name in LDAP (#{ldap_name}) different from scraped name (#{realname}) <br/>\n"
    end
  end
  return realname, new_user_id
end


def ldap_uid(realname) #Looks up full name in LDAP, returns user_id if it exists
  realname = Iconv.conv("ISO-8859-1", "UTF-8",realname).to_s
  realname = CGI.escape(realname)
  url="http://www.katalog.uninett.no/ldap/finn/?navn=#{realname}&org=uio&sok=s%F8k&valg1=cn"
  doc = Nokogiri::HTML.parse(open(url))
  doc.encoding = 'utf-8'
  doc.css("a").each do |a|
    name = a.inner_html
    href = a.attr("href")
    if( URI.decode(href) =~ /\/uid=([^,]*)/ )
      return $1
    end
  end
  return nil
end


def ldap_realname(username)
  begin # Workaround for bug in jruby-ldap-0.0.1:
    LDAP::load_configuration()
  rescue
  end
  conn = LDAP::Conn.new('ldap.uio.no', LDAP::LDAP_PORT)
  if conn.bound? then
    conn.unbind()
  end
  ansatt = nil
  conn.bind do
    conn.search2("dc=uio,dc=no", LDAP::LDAP_SCOPE_SUBTREE, "(uid=#{username})", nil, false, 0, 0).each do |entry|
      realname = entry.to_hash["givenName"][0] + " " + entry.to_hash["sn"][0]
      return realname
    end
  end
end


def get_list(url,rel_dest_url)
  html = open(url).read
  html = html.gsub("&nbsp;"," ").gsub("\n"," ").gsub("\r"," ") #Removes non-line-break and dos-line-break
  html = CGI.unescapeHTML(html) #remove HTML-encoding
  doc = Nokogiri::HTML.parse(html) 
  doc.encoding = 'utf-8'
  doc.css(".maincontent li a").each do |item|
    project_title = item.text.to_s
    href = item.attr("href").to_s
    href=~(/(.*\/)(.*)(\.xml)/)
    project_name = $2.to_s
    puts "\nProject title: " + project_title + "\nLocation: " + href
    @log = @log + "<br>\nProject title: " + project_title + "<br>\nLocation: " + href + "<br>\n"
    get_project(url,rel_dest_url,project_title,project_name,href)
    puts
  end
end


def get_project(url,rel_dest_url,project_title,project_name,href)
  new_link = rel_dest_url + project_name + "/index.html"
  old_link = href.to_s
  if(not(old_link =~ /^http\:/) and old_link =~ /\// and url =~ /^http\:/) #Finds fullpath
    uri = URI.parse(url)
    old_link = uri.scheme + "://" + uri.host + old_link
  end
  description = " "
  if(old_link)
    description, contact, image_src, members = scrape_html(old_link)
  else
    puts "WARNING: Invalid: " +old_link
    @log = @log + "WARNING: Invalid: " + old_link + "<br/>\n"  
  end
  publish_project(project_name, project_title, description, contact, members, rel_dest_url, image_src)
end


def scrape_html(url)
  html = open(url).read
  html = html.to_s.gsub("&nbsp;"," ").gsub("\n","").gsub("\r","").gsub(/"/,"'") #Removes non-break-space and dos-line-break
  doc = Nokogiri::HTML.parse(html)
  doc.encoding = 'utf-8'   
  doc.css("p").each do p
    if p && p.inner_html.gsub(/\s{2,}/,' ').strip == ""
      p.remove
    end
  end
  if(doc.css("#boxed #image img").size > 0)
    image_src = doc.css("#boxed #image img").attr("src").to_s
    image_src = Pathname.new(url).parent + image_src
    if !image_src.to_s.include?("http://") && url.to_s.include?("http://")
      uri = URI.parse(url)
      image_src = uri.scheme + "://" + uri.host + image_src
    end
  end
  contact = doc.css("#mailhomepage").inner_html
  members = Array.new
  doc.css("#projectmembers li").each do |list|
    if(list.css("a").size > 0)
      name = list.css("a").inner_html.to_s
    else
      name = list.text.to_s
    end
    realname, user_id = get_user(name)
    members << { :full_name => name, :realname => realname, :user_id => user_id}
  end
  members.each do |p|        
    if p[:user_id]!=nil && p[:user_id]!=""
      puts "Member: #{p[:full_name]}, LDAP-user-id: #{p[:user_id]}"
      @log = @log + "Member: #{p[:full_name]}, LDAP-user-id: #{p[:user_id]}<br/>\n"
    else
      puts "Member: #{p[:full_name]}, "
      @log = @log + "Member: #{p[:full_name]}<br/>\n"
    end
  end
  doc.css("#boxed").each {|node| node.remove} 
  doc.css("h1").each {|node| node.remove} 
  description=" "    
  description = "<p>" + doc.css("#main").inner_html + "</p>"
  description = description.gsub(/(\<!--.*\--\>)/,'')    #removes comments
  description = description.gsub(/\s{2,}/,' ')           #removes two or more adherent spaces and swaps " with '
  description = description.gsub(/style=\"[^\"]*\"/,"")  #removes inline style
  description = description.gsub(/"/,"'").gsub("\222","'").gsub("\n","")
  return description, contact, image_src, members 
end


def create_project_listing_folder(new_url, project_title)
  if(not(@vortex.exists?(new_url)))
    collection = Collection.new(:url => new_url, :title => project_title)
    path = @vortex.create(collection)
    puts "Creating folder: " + path
    @log = @log + "Creating folder: " + path + "<br/>\n"
  end
  props = '<v:userTitle xmlns:v="vrtx">' + project_title.to_s +  '</v:userTitle>'  
  begin
    @vortex.proppatch(new_url, props )
  rescue
    puts "Warning: problems patching folder: " + new_url
    @log = @log + "Warning: problems patching folder: " + new_url + "<br/>\n"
  end
end


def publish_project(project_name, project_title, description, contact, members, rel_dest_url, image_src)
  project_folder = rel_dest_url + project_name
  ref_list = get_reference_list("https://www.cees.uio.no/people/index.html")
  create_project_listing_folder(project_folder, project_title)
  @vortex.cd(project_folder + "/")
  url = rel_dest_url + project_folder+  "/index.html"  

  if !(image_src==nil || image_src=="")
    agent = Mechanize.new()
    agent.user_agent_alias = 'Mac Safari'
    page = agent.get(image_src)
    image_content = page.content
    ext = File.extname(image_src)
    new_image_url = project_folder + "/" + project_name + ext
    @vortex.put_string(new_image_url,image_content)
  else
    image_src = @project_img
    new_image_url = project_folder + "/project.png"
    if(not(@vortex.exists?(new_image_url)))
      @vortex.copy(@project_img,new_image_url)
    end
  end
  puts "Copying image: " + image_src.to_s + " => " + new_image_url
  @log = @log + "Copying image: " + image_src.to_s + " => " + new_image_url + "<br/>\n"
  url = project_folder + "/index.html"  
  participants_usernames = Array.new
  participants = Array.new
  members.each do |p|  
    presentation_url = ""
    if p[:user_id]!=nil && p[:user_id]!= ""
      participants_usernames.push(p[:user_id]) 
    else
      ref_list.each do |ref|
        if ref[:name]==p[:full_name]
          presentation_url = ref[:presentation_url]
        end
      end
     participants << { :participantName =>  p[:realname], :participantUrl => presentation_url}
    end
  end    
  project = {
    "resourcetype" => "structured-project",
    "properties" =>    {
      "content" => description,
      "picture" => new_image_url,
      "contactInfo" => contact,
      "name" => project_title,
      "status-ongoing" => "true",
      "introduction" => "",
      "participantsUsernames" => participants_usernames,
      "participants" => participants
    }
  }
  @vortex.put_string(url, project.to_json)
  
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
    "  <head><title>Prosjektliste</title></head>\n" +
    "  <body>\n" +
    "    <h1>" + Time.now.iso8601 + "<br>\nChangelog - prosjekter</h1>\n" + 
    @log + 
    "  </body>\n" +
    "</html>\n"
  File.open(logfil, 'a') do |f|
    f.write(@log)
  end
  puts "\nChangelog written to file: " + logfil
end


logfile = "konverteringslog-cees-projects.html"
url = "http://www.cees.uio.no/research/projects/index.xml"
dest_url = "https://www-dav.cees.uio.no/research/projects-new/"
rel_dest_url = "/research/projects-new/"

@log =""
@project_img = "http://cees.uio.no/research/projects-new/project.png"
@vortex = Vortex::Connection.new(dest_url,:use_osx_keychain => true)

get_list(url,rel_dest_url)

write_log(logfile)

  
