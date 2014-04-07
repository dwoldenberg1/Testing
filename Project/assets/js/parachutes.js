//***variable declarations***//

var level=1;

var bullet;
var parachuets;

var MultiPlayer=false;
var canvas = document.getElementById('frame');
var context = canvas.getContext('2d');

//game keys
var ESC = 27;
var SPACE = 32;

//***Beginning of main***//

$(document).ready(function() {
    $('body').keydown(keyPressedHandler);
});

function keyPressedHandler(e) {
	var code = (e.keyCode ? e.keyCode : e.which);
	
	switch(code) {
		case SPACE:	
			startGame();
			break;
		case ESC:
			endGame();
			break;
	}
 }
 
 function drawHub(player) {
	switch(player) {
		case one:
			context.fillStyle = 'red';
			context.strokeStyle = '#5B2701';
			break;
		case two:
			context.fillStyle = 'blue';
			context.strokeStyle = '#01125B';
			break;
	}
	context.beginPath();
	context.arc(325, 150, 50, 0, Math.PI, true);
	context.closePath();
	context.lineWidth = 5;
	context.fill();
	context.stroke();
}

function start(){
	$9('singleplayer'
	canvas.drawHub(player);
	bullets=array();
	parachutes=array();
	
}

//***defining parachute and bullet objects***//
function bullet(Slope, PosX, PosY)
{
var slope=Slope;
var posX=PosX;
var posY=PosY;
}

function parachute(Index, PosX, PosY)
{
var index=Index;
var posX=PosX;
var posY=PosY;
}
						