function succ(){
	x=document.getElementById("article")
	x.style.right=parseInt(x.style.right)+1300;
	x.style.left=parseInt(x.style.left)-1300;
}

function prev(){
	x=document.getElementById("article")
	x.style.right=parseInt(x.style.right)-1300;
	x.style.left=parseInt(x.style.left)+1300;
}