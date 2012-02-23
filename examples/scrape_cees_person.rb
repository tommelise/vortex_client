# -*- coding: utf-8 -*-
require 'rubygems'
require 'vortex_client'
require 'nokogiri'
require 'open-uri'
require 'uri'
require 'pry'
require "net/http"
require 'pathname'
require 'json'
require 'ldap'
require 'cgi'
require 'iconv'
require 'pathname'
require 'mechanize'
require 'ruby-debug'
include Vortex

#Legge personene i siden tilhørende mapper.
#få staff-liste til å fungere
#sette tittel på persondokumentene til å være lik full_name

def is_a_number?(s)
  s.to_s.match(/\A[+-]?\d+?(\.\d+)?\Z/) == nil ? false : true
end


def special_chars(str)
  char = {
    ['å','á','à','â','ä','ã','&aring;'] => 'a',
    ['æ','é','è','ê','ë','&eacute;','&aelig;'] => 'e',
    ['í','ì','î','ï','&iacute;'] => 'i',
    ['ø','ó','ò','ô','ö','õ','&oslash;'] => 'o',
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


def get_entire_staff_list(url,rel_dest_url)
  html = open(url).read
  html = html.gsub("&nbsp;"," ").gsub("\n"," ").gsub("\r"," ") #Removes non-line-break and dos-line-break
  html = CGI.unescapeHTML(html) #remove HTML-encoding
  doc = Nokogiri::HTML.parse(html) 
  doc.encoding = 'utf-8'
  new_doc = doc.css(".maincontent")
  introduction= ""
  new_doc.css(".vrtx-introduction").each do |intro|
    introduction = intro.inner_html
    intro.remove
  end
  name_list = get_name_list(new_doc)
#puts "new_doc: " + new_doc.inner_html
  new_doc = unescapeHTML(new_doc.inner_html)
  name_list.each do |name|
    new_doc = get_person(url,new_doc,rel_dest_url,name)
  end
# puts "new_doc: "+ new_doc
  puts "Number of names listed: " + name_list.size.to_s
  new_staff_list(new_doc,rel_dest_url,introduction)
end


def get_name_list(html)
  html.css("h1").each { |node| node.remove }
 # html.css("h2").each { |node| node.remove }
  name_list=Array.new
  html.css("table td").each do |cell|
    list = unescapeHTML(cell.inner_html)
    list = list.gsub(/\s{2,}/," ") #removes 2 or more space from string
    list = list.gsub("<br>","\n").gsub("<p>","\n").gsub("</p>","\n").gsub("/a><a","/a>\n<a").strip
    list = list.split("\n")
    name_list=name_list + list
  end
  name_list.delete_if{|element| element == "" || element == " " } # delete empty elements in list
#  name_list.delete_if{|element| element.include?("<h2>") }        # delete h2-elements in list
return name_list
end


def get_person(url,new_doc,rel_dest_url,name)
  if( URI.decode(name) =~ /<h2>([^<]*)/)
    @group_title = $1.gsub(/\(.*\)/,'').strip
    @group_name = @group_title.gsub(" ","").gsub("/","-").downcase!
    puts @group_title + " => " + @group_name
    create_person_listing_folder(rel_dest_url + @group_name ,@group_title)
  elsif !name.include?("<a")
    full_name = name.gsub(/\(.*\)/,'').strip
    user_id = get_user_id(full_name)
    new_link = rel_dest_url + @group_name + "/" + user_id.to_s + "/index.html"
    new_doc = new_doc.gsub(full_name,"<a href='"+new_link+"'>" + full_name +"</a>")
    puts "Name: #{full_name}, user_id: #{user_id}\nNo presentation => " + new_link.to_s
    @log = @log + "Name: #{full_name}, user_id: #{user_id}<br/>\nNo presentation => " + new_link + "<br/>\n"  
  elsif name.include?("<a")
    a = Nokogiri::HTML.parse(name) 
    name = a.css("a").inner_html
    href = a.css("a").attr("href")
    old_link = href.to_s
    if(not(old_link =~ /^http\:/) and old_link =~ /\// and url =~ /^http\:/) #Finds fullpath
      uri = URI.parse(url)
      old_link = uri.scheme + "://" + uri.host + old_link
    end
    if get_user(url,name,old_link)
      full_name, user_id = get_user(url,name,href)
      full_name = unescapeHTML(full_name)
      if (!user_id || user_id=="" || user_id.include?("-"))
        user_id = get_user_id(full_name)
      end
      new_link = rel_dest_url + @group_name + "/" + user_id.to_s + "/index.html"
      new_doc=new_doc.gsub(href.to_s, new_link)
      puts "Name: #{full_name}, user_id: #{user_id}\nOld presentation: #{old_link} => " + new_link.to_s
      @log = @log + "Name: #{full_name}, user_id: #{user_id}<br/>\nOld presentation: #{old_link} => " + new_link + "<br/>\n"
      @position = ""
      @phone = ""
      @email = ""
      description = " "
      image_src = ""
      if(old_link)
        description,image_src = check_old_link(old_link.to_s,user_id)  
      end
    end
  end
  if user_id!=nil && full_name!=nil && user_id!="" && full_name!=""
   publish_person(full_name, user_id, description, rel_dest_url, image_src)
  elsif name.include?("h2")
    puts "Group: "+ @group_name + ", title: " + @group_title
  else
    puts "Something amiss with this item"
  end
  puts
  return new_doc
end


def check_old_link(old_link,user_id)
  if (old_link =~/\/$/) #oldlink ends with "/" (It's a folder with an index-file)
    old_link=old_link + "index.html"
  end
  if old_link.include?(".xml")
    image_src = scrape_img_url(old_link,"#image img")
    description = scrape_xml(old_link,user_id)
  elsif old_link.include?("folk.uio.no")
    image_src = scrape_img_url(old_link,"img")
    description = scrape_html(old_link,user_id)
  elsif old_link.include?(".html")
    image_src = scrape_img_url(old_link,".vrtx-introduction-image")
    description = scrape_html(old_link,user_id)
  elsif (old_link.include?("sok?person") || (old_link==""))
    puts "No old website to scrape from"
    @log = @log + "No old website to scrape from.\n"
  else
    puts "WARNING: Invalid: " +old_link
    @log = @log + "WARNING: Invalid: " + old_link + "<br/>\n"
  end
  return description, image_src
end


def get_realname(name)
  name = name.gsub(/\(.*\)/,'').gsub(/\s{2,}/,' ')
  name_array = name.split(",")
  surname = name_array[0].strip
  firstname = name_array[1].strip
  return firstname, surname
end


def get_user(url,name,href)
  basename = Pathname.new(href).basename.to_s.gsub(/\..*/,'')    
  if(name.include? ",")then
    full_name = name.gsub(/\(.*\)/,'') #removes (*anytext) from full_name
    if(basename.include? "sok?person=") && !(basename.include? "mailto:")then 
      user_id = basename.gsub("sok?person=", "") 
    elsif (is_a_number?(basename))then #Frida_id
    else
      user_id = basename
    end
    return full_name, user_id
  else 
    return nil
  end 
end


def get_user_id(full_name)
  if(full_name =~ /,/)then
    full_name = full_name.split(/,/)
    full_name = full_name[1] + " " + full_name[0]
    full_name = full_name.strip 
  end
  ldap_user_id = find_uid(full_name)
  if (ldap_user_id) && full_name !="Merethe Andersen" && full_name != "Stine Dreyer" && full_name != "Marit Maanum Simonsen"
    new_user_id = ldap_user_id
    ldap_name = ldap_realname(ldap_user_id)
    puts "LDAP-user_id: " + new_user_id
    @log = @log + "LDAP-user_id: #{new_user_id}<br/>\n"
    @log = @log + "LDAP-name: #{ldap_name}<br/>\n" 
    if full_name != ldap_name 
      puts "WARNING: Possible mismatch. Name in LDAP different from scraped name</br>\n"
      @log = @log + "WARNING: Possible mismatch. Name in LDAP different from scraped name</br>\n"
    end
  else
    new_user_id = full_name.gsub(/\(.*\)/,'').downcase!        #removes parantheses with contents + downcase
    new_user_id = new_user_id.split(",").reverse.join("-")     #split name at ',' reverse order and join
    new_user_id = new_user_id.strip.gsub(" ","-").gsub(".","") #swap " " for "-" and remove "."
    new_user_id = special_chars(new_user_id).strip             #swap special-chars with web-friendly chars
    new_user_id = new_user_id.gsub("--","-")           
    puts "Pseudo_user: " + new_user_id
    @log = @log + "Pseudo_user: " + new_user_id + "<br/>\n"
  end
  return new_user_id
end


def find_uid(full_name) #Looks up full name in LDAP, returns user_id if it exists
  full_name = Iconv.conv("ISO-8859-1", "UTF-8",full_name).to_s
  full_name = CGI.escape(full_name)
  url="http://www.katalog.uninett.no/ldap/finn/?navn=#{full_name}&org=uio&sok=s%F8k&valg1=cn"
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


def scrape_xml(url,username)
  doc = Nokogiri::HTML.parse(open(url))
  doc.encoding = 'utf-8' 
  description="<h2>Background</h2>"  
  if username.include?("-")
    @position=doc.css("#title").text
    @phone = doc.css("#bodyblock #boxed p").inner_html.gsub("\n","").gsub("Phone:","").strip
    if (doc.css("#bodyblock #boxed #mailhomepage a").size > 0)
      @email = doc.css("#bodyblock #boxed #mailhomepage a").attr("href").to_s.gsub("mailto:","")
    end
  end
  doc.css("#bodyblock #boxed").each { |node| node.remove }
  doc.css("h1").each { |node| node.remove }
  doc.css("#title").each { |node| node.remove }
  doc.css("#bodyblock p").each do |p|
    if (p.text =="") 
      p.remove 
    end
  end
  doc.css("h2").each do |tittel2|
    if (tittel2.text =="Background") 
      tittel2.remove 
    end
  end
  doc.css("#bodyblock description").each do |desc|
    description = description + "<p>" +desc.inner_html + "<p>"
  end  
  description = description + doc.css("#bodyblock").inner_html
  if !(description == " ")
    description = description.gsub("\r","").gsub("\n","").gsub(/"/,"'")
    return description
  else
    return nil
  end
end


def scrape_html(url,username)
  html = open(url).read
  html = html.to_s.gsub("&nbsp;"," ").gsub("\n","").gsub("\r","").gsub(/"/,"'") #Removes non-break-space and dos-line-break
  doc = Nokogiri::HTML.parse(html)
  doc.encoding = 'utf-8' 
  description=" "  
  if url.include?("folk.uio.no")
    doc.css("body").each do |item|
      item.css("pre").each { |node| node.remove }
      item.css("hr").each { |node| node.remove }
      item.css("h1").each { |node| node.remove }
      if !username.include?("-") 
        item.css("#title").each { |node| node.remove }
      end
     description=item.inner_html
    end
  else
    doc.css(".maincontent").each do |item|
      doc.css(".vrtx-imagetext").each { |node| node.remove }
      if !username.include?("-")    
        doc.css(".vrtx-imagedescription").each { |node| node.remove }
      end
      doc.css("h1").each { |node| node.remove }
      doc.css(".vrtx-introduction-image").each { |node| node.remove }
      doc.css(".vrtx-byline").each { |node| node.remove }
      doc.css("#title").each { |node| node.remove }
      doc.css("description").each { |node| node.remove }
      description=item.inner_html
    end
  end
  description = description.gsub(/\<!--.*\-->/,'').gsub(/\<!--\n.*\-->/,'')       #removes comments
  description = description.gsub(/\s{2,}/,' ').gsub(/\s{2,}/,' ') #removes two or more adherent spaces
  description = description.gsub(/style=\"[^\"]*\"/,"")  #removes inline style
  description = description.gsub(/"/,"'").gsub("\n","").gsub("\r","").gsub("ó","o")
#  description = Iconv.conv("ISO-8859-1", "UTF-8",description).to_s
  description = description.gsub("<description xmlns:xsi='http://www.w3.org/2001/XMLSchema-instance'>","")
  description = description.gsub("</description>","")
  return description
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


def create_person_listing_folder(new_url,realname)
  if(not(@vortex.exists?(new_url)))
    collection = Collection.new(:url => new_url, :title => realname)
path=new_url
#    path = @vortex.create(collection)
    puts "Creating folder: " + path
    @log = @log + "Creating folder: " + path + "<br/>\n"
  end
  props = '<v:collection-type xmlns:v="vrtx">person-listing</v:collection-type>' +
    '<v:resourceType xmlns:v="vrtx">person-listing</v:resourceType>'+
    '<v:userTitle xmlns:v="vrtx">' + realname.to_s +  '</v:userTitle>'
  begin
#    @vortex.proppatch(new_url, props )
  rescue
    puts "Warning: problems patching folder: " + new_url
    @log = @log + "Warning: problems patching folder: " + new_url + "<br/>\n"
  end
end


def publish_person(full_name, username, description, rel_dest_url, image_src)
  person_folder = rel_dest_url + @group_name + "/" + username
  firstname, surname = get_realname(full_name)
  realname = firstname + " " + surname
  create_person_listing_folder(person_folder,realname)
  puts "image_src: " + image_src.to_s
 # puts description
  @vortex.cd(person_folder + "/")
  if !(image_src==nil || image_src=="")
    agent = Mechanize.new()
    agent.user_agent_alias = 'Mac Safari'
    page = agent.get(image_src)
    image_content = page.content
    ext = File.extname(image_src)
    new_image_url = rel_dest_url + @group_name + "/" + username + "/" + username + ext
 #   @vortex.put_string(new_image_url,image_content)
  else
    image_src = @placeholder
    new_image_url = rel_dest_url + @group_name + "/" + username + "/incognito.png"
    if(not(@vortex.exists?(new_image_url)))
 #     @vortex.copy(@placeholder,new_image_url)
    end
  end
  puts "Kopierer bilde: " + image_src.to_s + " => " + new_image_url
  @log = @log + "Kopierer bilde: " + image_src.to_s + " => " + new_image_url + "<br/>\n"
  new_url = rel_dest_url + @group_name + "/" + username + "/index.html"  
  person = {
    "resourcetype" => "person",
    "properties" => {
      "getRelatedGroups"=>"true",
      "getRelatedProjects"=>"true",
      "username" => username, 
      "getExternalScientificInformation"=>"true",
      "getExternalPersonInfo"=>"true",
      "content" => description, 
      "picture" => new_image_url}
  }
  if(username.include?("-"))
    person['properties']['username'] = " "
    person['properties']['firstName'] = firstname
    person['properties']['surname'] = surname
    person['properties']['getExternalPersonInfo'] = "false"
    person['properties']['position'] = @position
    person['properties']['phone'] = @phone
    person['properties']['email'] = @email
  end
#  @vortex.put_string(new_url, person.to_json)
  puts "Published: " + new_url
  @log = @log + "Published: " + new_url + "<br/>\n<br/>\n"
end


def new_staff_list(new_doc,rel_dest_url,introduction)
  # Writes new staff list. 
  new_doc=new_doc.gsub(/\<!--.*\-->/,'')
  new_doc=new_doc.gsub(/\s{2,}/,' ')
  new_doc=new_doc.gsub(/"/,"'")
  new_doc=new_doc.gsub(/style=\"[^\"]*\"/,"")
  @vortex.cd(rel_dest_url)
  url = rel_dest_url + "index.html"
  article  = Vortex::StructuredArticle.new(:title => "Staff",
                                           :introduction => introduction,
                                           :body => new_doc,
                                           :publishedDate => Time.now,
                                           :author => "",
                                           :url => url)
  path = @vortex.publish(article)
  puts
  puts "published " + path  
end


# Simple logger
def write_log(logfil)
  @log=  "<html>\n" +
    "  <head><title>Personpresentasjon</title></head>\n" +
    "  <body>\n" +
    "    <h1>" + Time.now.iso8601 + "<br>\nChangelog - nye personpresentasjoner</h1>\n" + 
    @log + 
    "  </body>\n" +
    "</html>\n"
  File.open(logfil, 'a') do |f|
    f.write(@log)
  end
  puts "\nChangelog written to file: " + logfil
end

def write_file(file)
  File.open(file, 'a') do |f|
    f.write(@namelist)
  end
  puts "\nName-mapping written to file: " + fil
end


def ldap_realname(username)
  begin
    # Workaround for bug in jruby-ldap-0.0.1:
    LDAP::load_configuration()
  rescue
  end
  ldap_host = 'ldap.uio.no'
  conn = LDAP::Conn.new(ldap_host, LDAP::LDAP_PORT)
  filter = "(uid=#{username})";
  base_dn = "dc=uio,dc=no"
  if conn.bound? then
    conn.unbind()
  end
  ansatt = nil
  conn.bind do

    conn.search2("dc=uio,dc=no", LDAP::LDAP_SCOPE_SUBTREE,
                 "(uid=#{username})", nil, false, 0, 0).each do |entry|
      brukernavn = entry.to_hash["uid"][0]
      fornavn = entry.to_hash["givenName"][0]
      etternavn = entry.to_hash["sn"][0]
      # epost = entry.to_hash["mail"][0]
      # adresse = entry.to_hash["postalAddress"][0]
      return fornavn + " " + etternavn
    end
  end
end

logfile = "konverteringslog.html"
url = "http://www.cees.uio.no/about/staff/"
dest_url = "https://www-dav.cees.uio.no/people/"
rel_dest_url = "/people/"
@position = ""
@phone = ""
@email = ""
@group_name = ""
@group_title = ""
@log =""
@placeholder = "http://www.cees.uio.no/test/people/incognito.png"

@vortex = Vortex::Connection.new(dest_url,:use_osx_keychain => true)

get_entire_staff_list(url,rel_dest_url)


test_doc = ""

# @group_name="researchersandpostdocs"
#get_person(url,test_doc, rel_dest_url, '<a href="http://www.cees.uio.no/about/staff/frida/127792.xml">Langangen, Øystein</a>')

# @group_name="masterstudents"
#get_person(url,test_doc, rel_dest_url, '<a href="http://www.cees.uio.no/news/new-faces/merethe-andersen.html">Andersen, Merethe</a>')

#get_person(url,test_doc, rel_dest_url, '<a href="http://www.uio.no/sok?person=nils" target="_blank" class="vrtx-link-check">Hjort, Nils Lid</a>')
#get_person(url,test_doc, rel_dest_url, '<a href="/about/staff/frida/3213.xml" class="vrtx-link-check">Vøllestad, Leif Asbjørn</a><br/>')
#get_person(url,test_doc, rel_dest_url, 'Bjørnæs, Ane Mari (Brysting)')

write_log(logfile)

  
