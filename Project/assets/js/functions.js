/*http://stackoverflow.com/questions/9301507/bootstrap-css-active-navigation
http://stackoverflow.com/questions/15521283/bootstrap-twitter-active-navigation-bar-changing-class-names-using-jquery*/

$(function(){

    $('.nav li a').on('click', function(e){

        //e.preventDefault(); // prevent link click if necessary?

        var $thisLi = $(this).parent('li');
        var $ul = $thisLi.parent('ul');

        if (!$thisLi.hasClass('active'))
        {
            $ul.find('li.active').removeClass('active');
                $thisLi.addClass('active');
        }

    })

})

$(document).ready(function() {
	//Spinner
	var opts = {
	  lines: 11, // The number of lines to draw
	  length: 11, // The length of each line
	  width: 4, // The line thickness
	  radius: 16, // The radius of the inner circle
	  corners: 0, // Corner roundness (0..1)
	  rotate: 0, // The rotation offset
	  direction: 1, // 1: clockwise, -1: counterclockwise
	  color: '#939292', // #rgb or #rrggbb or array of colors
	  speed: 1, // Rounds per second
	  trail: 50, // Afterglow percentage
	  shadow: false, // Whether to render a shadow
	  hwaccel: false, // Whether to use hardware acceleration
	  className: 'spinner', // The CSS class to assign to the spinner
	  zIndex: 2e9, // The z-index (defaults to 2000000000)
	  top: '50%', // Top position relative to parent
	  left: '50%' // Left position relative to parent
	};
	var target = document.getElementById('spin');
	var spinner = new Spinner(opts).spin(target);
});