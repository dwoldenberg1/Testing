//***********MAIN.js**********//
var gameBoard;
var paraExecutor;
var paraExec=null;
var bulletExecutor;

var paraSpeed=100;
var bulletSpeed=100;
var gameSpeed=5000;
var paraIncrement=5;
var bulletIncrement=10;
var levelNum = 1;

var crashes = 0;
var lives = 5;

var bullets=null;
var currentBullet=0;

var para=null;
var currentChute=0;
var parachute;

//actual field size(400px) divided by corresponding para size(4px)
var gameFieldRelativeWidth = 100;
var gameRegion = {gamexPos:650,gameyPos:300};

//width and height of para element
var paraElementWidth = 4;

//game keys here: http://www.cambiaresearch.com/articles/15/javascript-char-codes-key-codes
var ESC = 27;
var SPACE = 32;

$(document).ready(function() {
    $('body').keydown(keyPressedHandler);
});

function cont( number) {
	if(number<(levelNum*15)) {
		para[number]=new chute( (Math.floor(Math.random() * gameFieldRelativeWidth)* paraElementWidth),0);
		currentChute+=1;
		parachute=new chuteList();
		paraExec=setInterval(parachute.execEach(paraIncrement), paraSpeed);
		}
	else{
		nextLevel();
	}
};


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
 
 function mouseClickHandler(event) {
	 if(para!==null){
		 var pos = $('#gameField').position();
		 var relX = event.pageX - pos.left;
		 var relY = event.pageY - pos.top;
		 slopeOf = slope(relX, relY);
		 if (bullets.length<bulletIncrement){
		 	this.addBullet(currentBullet, slopeOf);
		 }
		 else{
		 	var index=0;
		 	while(bullets[index]!=null){index+=1;}
		 	bullet.addBullet(index, slopeOf)		 
		 }
	 }
 };
 
 function slope(xPos, yPos) {
	 var xFinal=325-xPos;
	 var yFinal=150-yPos;
	 
	 var slope=Math.round(yFinal/xFinal);
	 return slope;
 }

function startGame() {
	gameBoard = new GameBoard();
	bullets= null;
	currentBullet=0;
	currentChute=0;
	gameBoard.removeCannon();
	gameBoard.showCannon();
	
	parachute = new chuteList();
	para= new Array();
	
	bullets = new Array();
	bulletExecutor=setInterval(bullet.execBullet, 100);
	
	parachute.onCrash(parachuteCrashHandler,{gamexPos:650,gameyPos:300});
	paraExecutor = setInterval(cont(currentChute),gameSpeed);
};

function endGame() {
	if(paraExecutor) {
		clearInterval(paraExecutor);
		clearInterval(paraExec);
		if(bulletExecutor){
			clearInterval(bulletExecutor);
			}
	}
	gameBoard.clearBoard();
	
	gameBoard.removeCannon();
	crashes = 0;
	lives = 5;
	
	paraSpeed=100;
	bulletSpeed=100;
	gameSpeed=5000;
	paraIncrement=5;
	bulletIncrement=10;
	levelNum = 1;
};

function nextLevel() {
	bullets=null;
	para=null;
	clearInterval(paraExecutor);
	clearInterval(bulletExecutor);
	clearInterval(paraExec);
	levelNum+=1;
	paraIncrement=Math.round(paraIncrement*1.5);
	gameSpeed=Math.round(gameSpeed-(.15*gameSpeed));
	gameBoard.clearBoard();
	gameBoard.showNextRoundMsg();
};

function parachuteCrashHandler() {
	if(crashes>=lives){
		endGame();
		gameBoard.showLoseMessage();
	}
};

//*******para/bullet.js****//

function bullet(thisSlope, bulletX, bulletY) {
	this.bulletSlope=thisSlope;
	this.bulletXPos=Number(bulletX);
	this.bulletYPos=Number(bulletY);
	
	this.confirmedHit = function(xpos,ypos) {
		for(var i = 0; i< bullets.length; i++){
			for(var o=0; o<para.length; o++)
			//checks side-wall collision with 16 x 4 parachute and 4 x 4 bullet to save memory
			if(((bullets[i].bulletXPos <= para[o].chuteXPos && (bullets[i].bulletXPos+4) <= (para[o].chuteXPos+4))
			|| (bullets[i].bulletXPos >= para[o].chuteXPos && (bullets[i].bulletXPos+4) >= (para[o].chuteXPos+4)))
			&& ((bullets[i].bulletYPos <= para[o].chuteYPos && (bullets[i].bulletYPos+4) <= (para[o].chuteYPos+16))
			|| (bullets[i].bulletYPos >= para[o].chuteYPos && (bullets[i].bulletYPos+4) >= (para[o].chuteYPos+16))
			|| (bullets[i].bulletYPos >= para[o].chuteYPos && (bullets[i].bulletYPos+4) <= (para[o].chuteYPos+16)))) {
				gameBoard.updateScore(numLevel);
				$('div.bullet' + i).remove();
				$('div.parachute' + o).remove();
				return true;
			}
		}
		return false;
	};
	
	var execBullet = function(){
		for (var i=0; i<bullets.length; i+=1) {
			bullets[i].bulletYPos+=slopeOf;
			if (slopeOf<0) {bullet[i].bulletXPos-=1;}
			else {bullets[i].bulletXPos+=1;}
			gameBoard.drawElement('bullet',bullets[i].bulletXPos,bullets[i].bulletYPos);
		}
	};
	
	this.addBullet = function(index, slopeOf){
		currentBullet+=1;
		bullets[index]=new bullet(slopeOf, "325", "150");
	};
};

function chute(chuteX, chuteY) {
	this.chuteXPos=chuteX;
	this.chuteYPos=chuteY;
};

function chuteList() {
	var onCrashCallback;
	
	var atBottom = function(ypos) {
		if(ypos > gameRegion.gameyPos)
			return true;
		return false;
	};
	
	this.onCrash = function(crashCallback,fieldSize) {
		gameRegion = fieldSize;
		onCrashCallback = crashCallback;
	};
	
	var crash = function(thisChute){
		if(thisChute.chuteYPos >= gameRegion.gameyPos) {
			crashes+=1;
			updateLives();
			return true;
		}
		return false;
	};
	
	this.execEach= function(increment){
		for(var i=0; i<para.length; i+=1){
			var temp=para[i];
			temp.chuteYPos+=increment;
			gameBoard.drawElement('parachute' + currentChute,temp.chuteXPos,temp.chuteYPos);
			if(atBottom(para[i].chuteYPos)){
				gameBoard.removeChute(currentChute);
			}
			if(crash(temp)){
				onCrashCallback();
			}
		}
	};
};
//*******GAMEBOARD.js******//
function GameBoard() {

	this.drawElement = function (classname, xpos,ypos, counter) {
		var $element = $('<div/>').addClass(classname + counter);
		$element.css('top',ypos+'px').css('left',xpos+'px');
		$('#gameField').append($element);
	};
	
	this.clearBoard = function(){
		this.removeChutes();
		this.removeCannon();
		this.removeBullets();
	};
	
	this.showCannon = function() {
		$('#can').css('visibility','visible');
	};
	
	this.removeCannon = function() {
		$('#can').css('visibility','hidden');
	};
	
	this.removeChute = function(currentChute) {
		$('div.parachute' + currentChute).remove();
	};
	
	this.removeBullets = function() {
		$('div.bullet' + currentBullet).remove();
	};
	
	this.updateScore = function() {
		var $currentScore = Number($('#score').html());
		$currentScore = Number(currentScore.substring(17, 18));
		$currentScore+=1;
		$('#monsters').html("Monsters Killed: " + $currentScore);
	};
	
	this.updateLives = function() {
		var $currentLives = Number($('#lives').html());
		$currentLives = Number(currentScore.substring(6, 7));
		$currentLives-=1;
		$('#mlives').html("Lives: " + $currentLives);
	};
	
	this.showLoseMessage = function(){
		$('#loseMsg').css('visibility','visible');
	};
	
	this.showNextRoundMsg = function() {
		$('#nextRndMsg').hide().css({visibility: 'visible'}).fadeIn(2000);
		$('#nextRndMsg').fadeOut(2000, function() {
				$(this).show().css({visibility: 'hidden'});
			});
			
		var $currentLevel =$('#Level').html();
		$currentLevel = Number(currentLevel.substring(6, 7));
		$currentLevel+=1;
		$('#level').html("Level: " + $currentLevel);
	};
}
//************************//