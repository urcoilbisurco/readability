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
      #remove style and script
      @html.css("script, style, noscript").each{|i| i.remove}
      
      trasform_divs_into_paragraphs!
      
      #get all parent from p elements
      @parents=@html.css("p").map{ |p| p.parent }.compact.uniq
      
      #andidates=score_paragraphs
      cand=@parents.map{|p| [p, score(p)]}.max{|a,b| a[1]<=>b[1]}
      sanitize(cand[0])
      #sorted_candidates=@parents.sort{|a,b| score(a) <=> score(b)}
      #puts sorted_candidates.class
      #puts best_candidate=sorted_candidates.first
      #sanitize(best_candidate[:elem])

    end
    
    def sanitize(node)
      
      node.css("div").each do |el|
        counts=Hash[ %w[p img li a embed].each{|kind| [ kind, el.css(kind) ] } ]
        puts counts
        el.remove if (el.text.count(",")<10)
        #)&&(counts["p"]==0 || counts["embed"] > 0 || counts["a"]>counts["p"] || counts["li"]>counts["p"] || counts["img"]>counts["p"] )
      end
      
      whitelist=%w[div p]
      
      whitelist = Hash[whitelist.zip([true] * whitelist.size)]
      
      
      ([node]+node.css("*")).each do |el|
        if whitelist[el.node_name]
          el.attributes.each{|a,x| el.delete(a)}
        else
          el.swap(el.text)
        end
        
      end
      node.to_html.gsub(/[\r\n\f]+/,"\n").gsub(/[\t ]+/, " ").gsub(/&nbsp;/," ")
    end
    
    
    def trasform_divs_into_paragraphs!
      @html.css('*').each do |elem|
      
        if elem.name.downcase=="div"
          if elem.inner_html  !~ REGEXES[:divToPRe]
            puts "changed p"
            elem.name="p"
          end
        else
          #wrap text nodes in p tags
          elem.children.each do |child|
            if child.text?
              puts "changed child"
              child.swap("<p>#{child.text}</p>")
              #puts child.text?
              #puts child.text
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
    
    
    
    
  d=Readability::Document.new(File.open("sample.html"))
    
  puts d.content
  end
end