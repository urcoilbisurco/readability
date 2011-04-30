javascript:(
	
	function()
	{
    	location.href='http://localhost:4567/url?url='+ encodeURIComponent(window.location.href);
	}
  )()