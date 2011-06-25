# related_content
#
# Author: Lise Hamre

require 'rubygems'
require 'vortex_client'
require 'json'

class Related_content

  def initialize(host)
    @vortex = Vortex::Connection.new(host,:use_osx_keychain => true)
  end

  def alter_related_content(path,value)
    @vortex.find(path,:recursive => true,:filename=>/\.html$/) do |item|
       puts item.uri.to_s
      data = nil
      begin
        data = JSON.parse(item.content)
      rescue
        puts "Warning. Bad document. Not json:" + item.uri.to_s
      end
      if(data)
        if(value=="false_if_content") then
          if data["properties"]["related-content"] #&& data["properties"]["related_content"].strip != ""
            rel_cont_bottom = "false"
          else
            rel_cont_bottom = "true"
          end
        else rel_cont_bottom = value
        end
        data["properties"]["hideAdditionalContent"] = rel_cont_bottom
        item.content = data.to_json
      end
    end
  end

end


related_content = Related_content.new("https://www-dav.vortex-demo.uio.no")
path = "/personer/lise/."

## send related_content to bottom: (true/false/false_if_content)##
related_content.alter_related_content(path, "false_if_content")


