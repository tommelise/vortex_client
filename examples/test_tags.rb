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
        "tags" =>[
                  "word1",
                  "Word1",
                  "word2",
                  "Word2",
                  "word3",
                  "Word3"
                 ],
        "title" => "Tittel",
        "introduction" => "<p>Intro<\/p>\r\n",
        "hideAdditionalContent" => "false"
      }
    }
    @vortex.put_string("/personer/lise/test.html", testdoc.to_json)
  end

  def test_replace()
    tags = Tags.new("https://www-dav.vortex-demo.uio.no")
    tags.search_replace("/personer/lise/.", {"word1" => "new_word1", "word2" => "new_word2", "word3" => nil} )
    
    doc_tags = tags.tags("/personer/lise/test.html")
    assert doc_tags == ["Word1", "Word2", "Word3", "new_word1", "new_word2"]
  end

  def test_add()
    tags = Tags.new("https://www-dav.vortex-demo.uio.no")
    tags.add("/personer/lise/test.html", ["testtag","word1"])
    doc_tags = tags.tags("/personer/lise/test.html")
    # puts "Tags: " + doc_tags.join(", ")
    assert doc_tags ==["word1", "Word1", "word2", "Word2", "word3", "Word3", "testtag"]
  end

end
