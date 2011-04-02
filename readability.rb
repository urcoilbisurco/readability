# encoding: utf-8
require 'rubygems'
require 'open-uri'
require 'nokogiri'
require './utils'
require 'uri'

module Readability
  
  class Document
    
    def initialize(input)
      make_html(input)
    end
    
    def make_html(input)
      @html=Nokogiri::HTML(input, nil, 'UTF-8')

    end
    
    def content
      @html.css("script, style, noscript").each{|i| i.remove}
      
      trasform_divs_into_paragraphs!
      
      @html_title=@html.at_css("title").text
      @parents=@html.css("p").map{ |p| p.parent }.compact.uniq
      
      cand=@parents.map{|p| [p, score(p)]}.max{|a,b| a[1]<=>b[1]}
      cleaned_text=sanitize(cand[0])
      create_output!(cleaned_text)
      #create_style!
      create_title!
      
      #add style and node to output
      #@output.add_child(@style)
      @output.add_child(@title)
      @output.add_child(cleaned_text)

      #returns
      @output.to_html(:encoding=>"UTF-8").gsub(/[\r\n\f]+/,"\n").gsub(/[\t ]+/, " ").gsub(/&nbsp;/," ")

    end
    
    def sanitize(node)
      node.css("div").each do |el|
        link_density=get_link_density(el)
        content_length=el.text.strip.length
        if(el.text.count(",")<10)
          counts= %w[p img li a embed input].inject({}) {|m, kind| m[kind]=el.css(kind).length; m} 
          el.remove if counts["p"]==0 ||link_density>0.2 ||content_length<25 ||counts["li"]-10>counts["p"] || counts["input"]>counts["p"] || counts["embed"]>0

        end
      end
      
      whitelist=%w[div p li ul ol img a]
      
      whitelist = Hash[whitelist.zip([true] * whitelist.size)]
      
      
      ([node]+node.css("*")).each do |el|
        if whitelist[el.name]
          el.attributes.each{|a,x| el.delete(a) unless %[src href].include?(a)}
        else  
          el.swap(el.text)
        end
      change_image_src!(node)
      end
      node
      
    end
    
    def create_output!(node)
      @output=Nokogiri::XML::Node.new("div", node)
    end
    
    def get_link_density(elem)
      link_length=elem.css("a").map{|i| i.text}.join("").length
      text_length=elem.text.length
      
      link_length/text_length.to_f
   end
   
    def score(parent)
      score=0

        #change score based on class
        score-=50 if parent[:class] =~ REGEXES[:NotSoGoodCandidates]
        score+=25 if parent[:class] =~ REGEXES[:GreatCandidates]

        #change score based on id
        score-=50 if parent[:id] =~ REGEXES[:NotSoGoodCandidates]
        score+=25 if parent[:id] =~ REGEXES[:GreatCandidates]

        #change score based on # of commas
        score+=parent.text.count(",")
        score+=parent.css("p").size
      
      score
    end
  end
end

#  @@input=ARGV[0]
#a=open(@@input)
# d=Readability::Document.new(a)
 #d.content 
 #puts d.content
# File.open("file.html", 'w') {|f| f.write(d.content) }