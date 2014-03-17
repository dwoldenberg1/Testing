/*http://stackoverflow.com/questions/9301507/bootstrap-css-active-navigation
http://stackoverflow.com/questions/15521283/bootstrap-twitter-active-navigation-bar-changing-class-names-using-jquery*/

$(function(){

    $('.nav li a').on('click', function(e){

        e.preventDefault(); // prevent link click if necessary?

        var $thisLi = $(this).parent('li');
        var $ul = $thisLi.parent('ul');

        if (!$thisLi.hasClass('active'))
        {
            $ul.find('li.active').removeClass('active');
                $thisLi.addClass('active');
        }

    })

})