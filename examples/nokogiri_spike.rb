
require 'nokogiri'
require 'open-uri'

doc = <<-EOF
    <p><strong>tittel<\/strong><\/p>
<ul>
<li><a href="#"><\/a><\/li>
<\/ul>
<p><strong>tittel2<\/strong><\/p>
    EOF

html = Nokogiri::HTML(doc)

title = html.xpath("//p/strong")
next_title = title.parent.next
