require 'rubygems'
require 'nokogiri'
require 'open-uri'
module Readability
  class Document
    
    def initialize(input)
      make_html(input)
    end
    
    def make_html(input)
      @html=Nokogiri::HTML(input, nil, 'UTF-8')
    end
    
    def content
      @html.css("script, style, li").each{|i| i.remove}
      @html
    end
    
    d=Readability::Document.new(open("http://www.melablog.it/post/13704/ios-431-ha-davvero-migliorato-la-durata-della-batteria-sondaggio"))
    puts d.content
  end
end