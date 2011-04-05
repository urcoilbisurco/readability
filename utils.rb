module Readability
  
  class Document
    
    REGEXES={
      :DivToPRe             =>  /<(blockquote|div|dl|img|ol|p|pre|ul|table)/i,
      :NotSoGoodCandidates  =>  /<(comment|meta|footer|footnote|disqus|extra|sidebar|sponsor|popup)/i,
      :GreatCandidates      =>  /<(article|body|content|entry|main|page|pagination|post|text|blog|story)/i,
      :UrlRe                =>  /^(http\:\/\/[a-zA-Z0-9\-\.]+\.[a-zA-Z]{2,3}(?:\/\S*)?(?:[a-zA-Z0-9_])+\.(?:jpg|jpeg|gif|png))$/
    }
    
    def change_image_src!(node)
      node.css("img").each do |elem|      
          begin 
            create_true_url!(elem) if URI.split(elem.attribute('src'))[2].nil?
          rescue
            elem.remove
          end
      end  
    end
    
    def create_true_url!(elem) 
      string=URI.parse(@@input) + elem.attribute("src").to_s #elem.attribute("src").to_s
      elem.set_attribute("src", string.to_s)
    end
    
    def is_a_bad_element?(elem)
      x=false
      %w[class id].each do |e|
        x= x | (!elem[e].nil? && %w[comment ad sidebar].any?{|a| elem[e].include?(a)})
      end
      x
    end
    
    def trasform_divs_into_paragraphs!
      @html.css('*').each do |elem|
      
        if %w[div span].any?{|a| elem.name.downcase.eql?(a)}
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
    
  end
end