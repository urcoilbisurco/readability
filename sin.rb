require 'rubygems'
require 'sinatra'
require './readability'
require 'erb'
require 'cgi'
get '/' do
  @action='index'
  erb :index
end
post '/url' do
  @action='url'
  @@input=params[:url]
  @cont=Readability::Document.new(open(@@input)).content
  
  erb :url
end




__END__
@@layout
<html>
  <head><link rel="stylesheet" href=<%="#{@action}.css"%> type="text/css"></head>
  <body>
    <%= yield %>
  </body>
</html>


@@ index
hi!
<form action="url" method="post">
    <table>
      <tr>
        <td>url</td>
        <td><input name="url" /></td>
      </tr>
    </table>
    <input type="submit" value="view" />
  </form>
  
@@url
<div>
<%= @cont %>
</div>