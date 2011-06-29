# related_content
# This program moves related content from right to bottom or vice versa
# Value: false_if_content: If related content has contents, you can choose to leave it at the right hand side
# def image_width can control the position movement based on the size of the immage.
# def image_size kan resize images to fit better at wide or narrow body-with (NOT TESTED)
# Author: Lise Hamre

require 'rubygems'
require 'vortex_client'
require 'json'

class Position_related_content

  def initialize(host)
    @vortex = Vortex::Connection.new(host,:use_osx_keychain => true)
  end

  def position_value(path)
    doc = @vortex.get(path)
    data = JSON.parse(doc)
    if(data["properties"]["hideAdditionalContent"])
      return data["properties"]["hideAdditionalContent"]
    else
      return []
    end
  end

  def parse_css(css)
    css_hash = { }
    css.split(/;/).each do |item|
      item = item.split(/:/)
      css_hash[ item[0].gsub(/\s/,'') ] = item[1].gsub(/\s/,'').gsub("px","")
    end
    return css_hash
  end
  
  
  def image_size(data,filename,new_width)
    content = data["properties"]["content"]
    if content !=nil
      html = Nokogiri::HTML.parse(content)
      if html != nil
        html.css("img").each do |image|
          style = image.attr("style")
          if style != nil
            dim = parse_css(style)
            if dim["width"].to_i > 500 && dim["width"].to_i < new_width
              puts filename
              #          puts "width: " + dim["width"].to_s + " height: " + dim["height"].to_s
              new_height = (new_width/(dim["width"].to_f))*dim["height"].to_f
              new_style = "width:  " + new_width.to_s + "; height: " + new_height.round.to_s + ";"
              #          puts "New_style: " + new_style 
              html = html.to_s.gsub(style,new_style)
            end
          end
        end
      end
      content = html.to_s.gsub("<html>","").gsub("</html>","").gsub("<body>","").gsub("</body>","")
      #      puts "content: " + content
      data["properties"]["content"] = content
    end
    return data
  end
  
  
  def wide_image(data, filename, width)
    wide_image = false
    content = data["properties"]["content"]
    if content !=nil
      html = Nokogiri::HTML.parse(content)
      if html != nil
        html.css("img").each do |image|
          style = image.attr("style")
           if style != nil
             dim = parse_css(style)
             if dim["width"].to_i > width
               puts filename
               puts "width: " + dim["width"].to_s + " height: " + dim["height"].to_s
               wide_image = true
              end
           end
        end
      end
    end
    return wide_image
  end
  

  def position_related_content(path,value,img_width)
    @vortex.find(path,:recursive => true,:filename=>/\.html$/) do |item|
#      puts item.uri.to_s
      rel_cont_bottom = value
      data = nil
      begin
        data = JSON.parse(item.content)
      rescue
        puts "Warning. Bad document. Not json:" + item.uri.to_s
      end
      if(data)
        if(value=="false_if_content") then
          if data["properties"]["related-content"] #&& data["properties"]["related_content"].to_s.strip != ""
            rel_cont_bottom = "false"
          else
            rel_cont_bottom = "true"
          end
        end
#        data = image_size(data,item.uri.to_s,img_width) 
#        if wide_image(data,item.uri,img_width)
#          rel_cont_bottom = false
#        end
#        puts "related content at bottom: " + rel_cont_bottom.to_s
        data["properties"]["hideAdditionalContent"] = rel_cont_bottom
        item.content = data.to_json
      end
    end
  end

end


position_related_content = Position_related_content.new("https://www-dav.vortex-demo.uio.no")
path = "/personer/lise/."

#position_related_content = Position_related_content.new("https://www-dav.uio.no/")
#path = "/forskning/tverrfak/culcom/nyheter/."

## send related_content to bottom: (true/false/false_if_content,img_with)##
position_related_content.position_related_content(path, "true",500)

