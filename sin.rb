require 'rubygems'
require 'sinatra'
require 'open-uri'
require './readability'
require 'erb'
require 'cgi'
get '/' do
  @action='index'
  erb :index
end
get '/url' do
  @action='url'
  @@input=params[:url]
  @cont=Readability::Document.new(open(@@input)).content
  
  erb :url
end
get'/demo' do 
  @action='url'
  @@input="sample.html"
  @cont=Readability::Document.new(open(@@input)).content
  erb :url
end




__END__

@@ index
hi!
drag this bookmarklet to use the service:
<%= erb :bookmarklet, :layout => false %>

<form action="url" method="get">
    <table>
      <tr>
        <td>url</td>
        <td><input name="url" /></td>
      </tr>
    </table>
    <input type="submit" value="view" />
  </form>
