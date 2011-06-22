# Search replace
#
# Author: Lise Hamre & Thomas Flemming

#  tags = Tags.new("https://vortex-dav.uio.no/brukere/lise/test/")
#  keywords = {"word1" => "new_word1", "word2" => "new_word2"}
#  tags.search_replace(path, keywords)

require 'rubygems'
require 'vortex_client'
require 'json'

class Tags

  def initialize(host)
    @vortex = Vortex::Connection.new(host,:use_osx_keychain => true)
  end

  # TODO Make this more robust:
  #  - return [] if no tags
  def tags(path)
    doc = @vortex.get(path)
    data =  JSON.parse(doc)
    return data["properties"]["tags"]
  end

  def add(path, new_tags)
    tags_on_server = tags(path)
    doc = @vortex.get(path)
    data =  JSON.parse(doc)
    tags_on_server += new_tags
    data["properties"]["tags"] = tags_on_server.uniq
    @vortex.put_string(path, data.to_json  )
  end

  def search_replace(path, tags)
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
        # puts "keywords: " + tags_on_server.join(", ")
        tags.each do |tag, new_tag|
          #puts "tag" + tag.to_s + new_tag.to_s 
          if(tags_on_server.grep(tag))then
            tags_on_server.delete(tag)
            if(new_tag)then
              tags_on_server.push(new_tag)
            end
          end
        end

        data["properties"]["tags"] = tags_on_server
        item.content = data.to_json
      end


    end
  end

end
