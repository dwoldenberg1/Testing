//***variable declarations***//

var bullet;
var parachuets;

var MultiPlayer=false;
var canvas = document.getElementById('frame');
var context = canvas.getContext('2d');

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