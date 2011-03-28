require 'rubygems'
require 'open-uri'
require 'nokogiri'


module Readability
  
  
  
  
  class Document
    
    
    REGEXES={
      :DivToPRe             =>  /<(blockquote|div|dl|img|ol|p|pre|ul|table)/i,
      :NotSoGoodCandidates  =>  /<(comment|meta|footer|footnote|disqus|extra|sidebar|sponsor|popup)/i,
      :GreatCandidates      =>  /<(article|body|content|entry|main|page|pagination|post|text|blog|story)/i,
      :UrlRe                =>  /^(http\:\/\/[a-zA-Z0-9\-\.]+\.[a-zA-Z]{2,3}(?:\/\S*)?(?:[a-zA-Z0-9_])+\.(?:jpg|jpeg|gif|png))$/i
    }
    
    
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
      sanitize(cand[0])

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
      
      whitelist=%w[div p li ul img a]
      
      whitelist = Hash[whitelist.zip([true] * whitelist.size)]
      
      
      ([node]+node.css("*")).each do |el|
        if whitelist[el.name]
          el.attributes.each{|a,x| el.delete(a) unless %[src href].include?(a)}
        else
          
          el.swap(el.text)
        end
      change_image_src!(node)
     
        
      end
      node.to_html(:encoding=>"UTF-8").gsub(/[\r\n\f]+/,"\n").gsub(/[\t ]+/, " ").gsub(/&nbsp;/," ")
      
      create_output!(node)
      create_style!
      create_title!
      
      
      #add style and node to output
      @output.add_child(@style)
      @output.add_child(@title)
      @output.add_child(node)
      
      #returns
      @output
      
    end
    def change_image_src!(node)
      node.css("img").each do |elem|
        
        elem.attributes.each do |a,x|
          #very strange code
          if a=="src"
            puts x; 
            reg=(/^(http\:\/\/[a-zA-Z0-9\-\.]+\.[a-zA-Z]{2,3}(?:\/\S*)?(?:[a-zA-Z0-9_])+\.(?:jpg|jpeg|gif|png))$/)
            unless reg.match(x)?true:false
              elem.delete(a)
            end
          end 
        end
      end
    end
    
    def trasform_divs_into_paragraphs!
      @html.css('*').each do |elem|
      
        if elem.name.downcase=="div"
          if elem.inner_html  !~ REGEXES[:DivToPRe]
            puts "changed p"
            elem.name="p"
          end
       # else

          #wrap text nodes in p tags
        #  elem.children.each do |child|
        #    if child.text?
        #      puts "changed child"
        #      child.swap("<p>#{child.text}</p>")    
        #    end
        #  end

        end
      end
      
    end
    def create_title!
      
      @title = Nokogiri::XML::Node.new("h2",@output)
      @title.content=@html_title
      
      @title
    end
    
    
    def create_style!
      @style = Nokogiri::XML::Node.new("style", @output)
      @style.set_attribute("type","text/css")
      #simple example of style
      @style.content="body{background-color:#EDEDED;}"
      @style.to_html(:encoding=>"UTF-8").gsub(/[\r\n\f]+/,"\n").gsub(/[\t ]+/, " ").gsub(/&nbsp;/," ")
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
    
    
    
    
  d=Readability::Document.new(open(ARGV[0]))
  #d.content 
  #puts d.content
  File.open("file.html", 'w') {|f| f.write(d.content) }
  end
end