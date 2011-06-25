require 'rubygems'
require 'test/unit'
require 'vortex_client'
require 'json'
require 'position_related_content'

class TestPosition_related_content < Test::Unit::TestCase

  def setup
    @vortex = Vortex::Connection.new("https://www-dav.vortex-demo.uio.no",:use_osx_keychain => true)
    testdoc = {
      "resourcetype" => "structured-article",
      "properties" => {
#        "tags" =>[],
        "title" => "Tittel",
        "introduction" => "<p>Intro<\/p>\r\n",
        "hideAdditionalContent" => "false",
        "related-content" => "<p>Relaterte greier<\/p>\r\n"
#        "related-content" => ""
      }
    }
    @vortex.put_string("/personer/lise/test.html", testdoc.to_json)
  end


  def test_positon_related_content()
    position_related_content = Position_related_content.new("https://www-dav.vortex-demo.uio.no")
    path = "/personer/lise/."
    position_related_content.position_related_content(path, "false_if_content")
    rel_content_bottom = position_related_content.position_value("/personer/lise/test.html")
    assert rel_content_bottom == "false"
  end

end
