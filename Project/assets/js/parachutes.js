 //***variable declarations***//
var ctx;
var background;

//Game Dimensions
var gameY;
var gameX;

window.onload = function() {
    //credit where credit is due:http://stackoverflow.com/questions/6796194/canvas-getcontext2d-returns-null
<<<<<<< HEAD
    var canvas = document.getElementById('frame');
    /*var preCtx*/ctx = canvas.getContext('2d');
    
    gameX=document.getElementById("game").clientWidth;
    gameY=document.getElementById("game").clientHeight;
    alert(gameY + ":" + gameX);
    
    loadListeners();
    //background=preCtx; //need to think about this
    //ctx=preCtx;
=======
    var canvas = document.createElement('canvas');
    var preCtx = canvas.getContext('2d');
    loadListeners();
    background=preCtx; //need to think about this
    ctx=preCtx;

    canvas.width = gameX;
    canvas.height = gameY;
    canvas.setAttribute('id', 'frame');
    document.('#game').appendChild(canvas);
>>>>>>> FETCH_HEAD
}

var level = 1;
var Player;
var bullettMax=10;
var paraMax = level * 15;

var bullets;
var Bindex=0;
var parachutes;
var Pindex;

var game = new GameBoard();

//game keys
var ESC = 27;
var SPACE = 32;

//***Beginning of main***//

$(document).ready(function () {
    $('body').keydown(keyPressedHandler);
    var $element = $('<div/>').addClass('message');
    $element.css('visbility', 'hidden');
    $('#game').append($element);
    var $element = $('<div/>').addClass('message')
    $('.message').html('Click Space to Start!');
    $('.message').hide().css({
        visibility: 'visible'
    }).fadeIn(2000);
});

function keyPressedHandler(e) {
    var code = (e.keyCode ? e.keyCode : e.which);
    switch (code) {
        case SPACE:
            $('.message').fadeOut(2000, function () {
                $(this).show().css({
                    visibility: 'hidden'
                });
            });
            $('#singleplayer').css('visibility', 'visible');
            $('#multiplayer').css('visibility', 'visible');
            break;
        case ESC:
            end();
            break;
    }
}

function start(player) {
    Player=player;
    game.drawHub(player);
    alert("gameHub worked");
    bullets = new Array();
    parachutes = new Array();
    gameListeners();

}

function nextLvl() {
   level++;
   paraMax = level * 15;
}

function slope(x, y) {
	 var xFinal=gameX-x;
	 var yFinal=gameY-y;
	 
	 var slope=Math.round(yFinal/xFinal);
	 return slope;
}

//***defining parachute and bullet objects***//

function bullet(Slope, PosX, PosY, Index) {
    var slope = Slope;
    var posX = PosX;
    var posY = PosY;
    var index = Index;

    this.drawBullet = function(xpos, ypos){
	Slope=slope(xpos, ypos);
	if(bullets.length<=bulletMax){
	    bullets[Bindex]= new bullet(Slope, xpos, ypos, Bindex);
	    Bindex++;
	    game.draw();
	}
    }

}

function parachute(Index, PosX, PosY) {
    var index = Index;
    var posX = PosX;
    var posY = PosY;

    this.drawParachute = function(){
	if(parachutes.length<=paraMax){
	    var xpos;
	    var ypos; //need to updadte dimensions (own section where declaring variables)
	    parachutes[Pindex]= new parachute(xpos, ypos, Pindex);
	    Pindex++;
	    game.draw();
	}
    }
}

//***canvas gameboard***//
function GameBoard() {

    this.drawHub = function (player) {
        switch (player) {
            case 'one':
                ctx.fillStyle = 'red';
                ctx.strokeStyle = '#5B2701';
                var hubX=Math.round(gameX/2);
                break;
            case 'two':
                ctx.fillStyle = 'blue';
                ctx.strokeStyle = '#01125B';
                var hubX=Math.round(gameX * (1/3));
                break;
        }
        alert("color, hub worked, typeOf(ctx)=" + typeof ctx + " hubX=" + hubX + "gameY=" +gameY);
        ctx.beginPath();
        ctx.arc(hubX, gameY, 50, 0, Math.PI, true); //context.arc(centerX, centerY, radius, 0, 2 * Math.PI, false);
        ctx.closePath();
        ctx.lineWidth = 5;
        ctx.fill();
        ctx.stroke();
        alert("circle was drawn at " + hubX + ", " +Math.round(gameY/2));
    }

    this.drawElement = function (xpos, ypos) {
        ctx.beginPath();
        ctx.moveTo(xpos, ypos);
        ctx.lineTo(xpos + 3, ypos + 7);
        ctx.stroke();
    };

    this.clearBoard = function () {
        ctx.clearRect(0, 0, canvas.width, canvas.height);
    };

    this.draw = function(){
        this.drawHub(Player);
	parachutes.forEach(function(entry) {
    	    this.drawElement(entry.posX, entry.posY);
	});
	bullets.forEach(function(entry) {
    	    this.drawElement(entry.posX, entry.posY);
	});
    };  
}

//***Event Listeners***//

function loadListeners(){
    document.getElementById('singleplayer').addEventListener('click', function () {
        $('#singleplayer').fadeOut(2000, function () {
            $(this).show().css({
                visibility: 'hidden'
            });
        });
        $('#multiplayer').fadeOut(3500, function () {
            $(this).show().css({
                visibility: 'hidden'
            });
        });
        start('one')
    }, false);

    document.getElementById('multiplayer').addEventListener('click', function () {
        $('#multiplayer').fadeOut(2000, function () {
            $(this).show().css({
                visibility: 'hidden'
            });
        });
        $('#singleplayer').fadeOut(3500, function () {
            $(this).show().css({
                visibility: 'hidden'
            });
        });
        start('two')
    }, false);
    
    $('#frame').css('height',gameY+'px').css('width',gameX+'px');

}

function gameListeners() {
    document.getElementById('game').addEventListener('click', bullet.drawBullet(e.clientx, e.clienty) ); //http://www.kirupa.com/html5/getting_mouse_click_position.htm
}