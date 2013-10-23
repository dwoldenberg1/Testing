window.onload= function(){$(document).ready(function() {
	$('.chapter-3').mouseenter(function(){
        $('.chapter-3').fadeTo('fast',1);
    });
    $('.chapter-3').mouseleave(function(){
        $('.chapter-3').fadeTo('fast',0.5);
    });
});}