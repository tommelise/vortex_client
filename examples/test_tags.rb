require 'rubygems'
require 'test/unit'
require 'vortex_client'
require 'json'
require 'tags'

class TestTags < Test::Unit::TestCase

  def setup
    @vortex = Vortex::Connection.new("https://www-dav.vortex-demo.uio.no",:use_osx_keychain => true)
    testdoc = {
      "resourcetype" => "structured-article",
      "properties" => {
#        "tags" =>[],
        "title" => "Tittel",
        "introduction" => "<p>Intro<\/p>\r\n",
        "hideAdditionalContent" => "false"
      }
    }
    @vortex.put_string("/personer/lise/test.html", testdoc.to_json)
  end

  def test_replace()
    tags = Tags.new("https://www-dav.vortex-demo.uio.no")
    tags.alter_tags("/personer/lise/.", {"word1" => "new_word1", "word2" => "new_word2", "word3" => nil},"replace" )
    doc_tags = tags.tags("/personer/lise/test.html")
    puts "replace-Tags: " + doc_tags.join(", ")
    assert doc_tags == []
  end
  
  def test_add()
    tags = Tags.new("https://www-dav.vortex-demo.uio.no")
    tags.alter_tags("/personer/lise/test.html", ["testtag","word1"],"add")
    doc_tags = tags.tags("/personer/lise/test.html")
    puts "add-Tags: " + doc_tags.join(", ")
    assert doc_tags ==["testtag","word1"]
  end

end
