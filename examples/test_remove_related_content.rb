require 'rubygems'
require 'test/unit'
require 'vortex_client'
require 'json'
require 'position_related_content'

class TestRemove_related_content < Test::Unit::TestCase

  def setup
    @vortex = Vortex::Connection.new("https://www-dav.vortex-demo.uio.no",:use_osx_keychain => true)
    testdoc = {
      "resourcetype" => "structured-article",
      "properties" => {
#        "tags" =>[],
        "title" => "Tittel",
        "introduction" => "<p>Intro<\/p>\r\n",
        "hideAdditionalContent" => "false",
        "related-content" => "<p><strong>Relaterte greier<\/strong><\/p>\r\n<p><a href=\"http://www.uio.no\">ekstern lenke<\/a><\/p>\r\n<p><a href=\"http://www.vortex-demo.uio.no/personer/lise/artikkel.html\">intern lenke<\/a><\/p>\r\n<p><a href=\"/personer/lise/artikkel.html\">relativ intern lenke<\/a><\/p>\r\n<p><a href=\"artikkel.html\">lokal lenke<\/a><\/p>\r\n"
      }
    }
    @vortex.put_string("/personer/lise/test.html", testdoc.to_json)
  end


  def test_positon_related_content()
    remove_related_content = Remove_related_content.new("https://www-dav.vortex-demo.uio.no")
    path = "/personer/lise/."
    remove_related_content.remove_related_content(path)
    rel_content = remove_related_content.remove_value("/personer/lise/test.html")
    assert rel_content == ""
  end

end
