# related_content
#
# Author: Lise Hamre

require 'rubygems'
require 'vortex_client'
require 'json'

class Position_related_content

  def initialize(host)
    @vortex = Vortex::Connection.new(host,:use_osx_keychain => true)
  end

  def position_related_content(path,value)
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


position_related_content = Position_related_content.new("https://www-dav.vortex-demo.uio.no")
path = "/personer/lise/."
#positionrelated_content = Position_related_content.new("https://www-dav.uio.no/")
#path = "/forskning/tverrfak/culcom/nyheter/."

## send related_content to bottom: (true/false/false_if_content)##
position_related_content.position_related_content(path, "false_if_content")


