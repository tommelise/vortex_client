# -*- coding: utf-8 -*-
require 'rubygems'
require 'test/unit'
require 'vortex_client'
require 'json'
require 'html2json'
require 'open-uri'
require 
class TestHtml2JSON < Test::Unit::TestCase

  def setup
    @testfile = '/konv/test/testfil.html'
    @vortex = Vortex::Connection.new("https://www-dav.vortex-demo.uio.no",:use_osx_keychain => true)
    @vortex.delete(@testfile)
  end

  def test_encoding_conversion
    assert( convert_encoding($test_string, "æøå ÆØÅ"))
    aring_iso8859 = '\xE5'
    aring_utf8    = 'å'
    aring_cp
  end

  def test_spike
    src = '/konv/src_file.html'
    convert_to_json(src,@testfile)
    content = open('https://www-dav.vortex-demo.uio.no' + src).read
    assert(content[/å/])
  end

end
