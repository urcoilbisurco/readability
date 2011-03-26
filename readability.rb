require 'rubygems'
require 'open-uri'
require 'nokogiri'


module Readability
  
  
  
  
  class Document
    
    
    REGEXES={
      :divToPRe             =>  /<(a|blockquote|div|dl|img|ol|p|pre|ul|table)/i,
      :NotSoGoodCandidates  =>  /<(comment|meta|footer|footnote|disqus|extra|sidebar|sponsor|popup)/i,
      :GreatCandidates      =>  /<(article|body|content|entry|main|page|pagination|post|text|blog|story)/i
    }
    
    
    def initialize(input)
      make_html(input)
    end
    
    def make_html(input)
      @html=Nokogiri::HTML(input, nil, 'UTF-8')
    end
    
    def content
      @html.css("script, style, noscript").each{|i| i.remove}
      
      @parents=@html.css("p").map{ |p| p.parent }.compact.uniq
      
      cand=@parents.map{|p| [p, score(p)]}.max{|a,b| a[1]<=>b[1]}
      sanitize(cand[0])

    end
    
    def sanitize(node)
      node.css("div").each do |el|
        
        content_length=el.text.strip.length

        if(el.text.count(",")<10)
          to_remove=false
          counts= %w[p img li a embed input].inject({}) {|m, kind| m[kind]=el.css(kind).length; m} 
          if counts["p"]==0
            to_remove=true
          #elsif counts["img"]>counts["p"]
            to_remove=true
          elsif content_length<25
            to_remove=true
          elsif counts["li"]>counts["p"]
            to_remove=true
          elsif counts["input"]>counts["p"]
            to_remove=true
          elsif counts["embed"]>0
            to_remove=true
          end
          
          if to_remove
            el.remove
          end
        end
      end
      
      whitelist=%w[div p]
      
      whitelist = Hash[whitelist.zip([true] * whitelist.size)]
      
      
      ([node]+node.css("*")).each do |el|
        if whitelist[el.node_name]
          el.attributes.each{|a,x| el.delete(a)}
        else
          
          el.swap(el.text) unless el.name=="img"
        end
        
      end
      node.to_html.gsub(/[\r\n\f]+/,"\n").gsub(/[\t ]+/, " ").gsub(/&nbsp;/," ")
    end
    
    
    def trasform_divs_into_paragraphs!
      @html.css('*').each do |elem|
      
        if elem.name.downcase=="p"
          if elem.inner_html  !~ REGEXES[:divToPRe]
            puts "changed p"
            elem.name="div"
          end
        else
          #wrap text nodes in p tags
          elem.children.each do |child|
            if child.text?
              puts "changed child"
              child.swap("<p>#{child.text}</p>")
             
            end
          end
        end
      end
      
      
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
    
    
    
    
  d=Readability::Document.new(open(ARGV[0]))
    
  puts d.content
  end
end