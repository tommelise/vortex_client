# Search replace
#
# Author: Lise Hamre & Thomas Flemming

require 'rubygems'
require 'vortex_client'
require 'json'

class Tags

  def initialize(host)
    @vortex = Vortex::Connection.new(host,:use_osx_keychain => true)
  end

  def tags(path)
    doc = @vortex.get(path)
    data =  JSON.parse(doc)
    if(data["properties"]["tags"])
      return data["properties"]["tags"]
    else
      return []
    end
  end

  def add(tags_on_server, new_tags)
    if(tags_on_server)then
      return tags_on_server += new_tags
    else
      return tags_on_server = new_tags
    end
  end

  def search_replace(tags_on_server, tags)
    if(tags_on_server)then
      tags.each do |tag, new_tag|
        if(tags_on_server.include?(tag))then
          tags_on_server[tags_on_server.index(tag)]=new_tag
          tags_on_server.flatten
         puts tag.to_s + " => " + new_tag.to_s 
       end
      end
    end
     return tags_on_server
  end

  def alter_tags(path,tags,alteration)
    @vortex.find(path,:recursive => true,:filename=>/\.html$/) do |item|
      # puts item.uri.to_s
      data = nil
      begin
        data = JSON.parse(item.content)
      rescue
        puts "Warning. Bad document. Not json:" + item.uri.to_s
      end
      if(data)then
        tags_on_server = data["properties"]["tags"]       
        if alteration=="add"
          tags_on_server = add(tags_on_server, tags).uniq
        elsif alteration=="replace"
          tags_on_server = search_replace(tags_on_server, tags)
        end
        data["properties"]["tags"] = tags_on_server
        item.content = data.to_json
      end
    end
  end

end

tags = Tags.new("https://www-dav.vortex-demo.uio.no")
path = "/personer/lise/."

## Replace tags: ##
keywords = {"word2" => "word6", "word3" => "word5"}
#tags.alter_tags(path, keywords, "replace")

## Add tags: ##
new_tags = ["new-tag1", "new-tag2"]
tags.alter_tags(path, new_tags, "add")


