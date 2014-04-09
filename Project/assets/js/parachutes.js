 //***variable declarations***//

var level = 1;

var bullet;
var parachuets;

var MultiPlayer = false;
var canvas = document.getElementById('frame');
var ctx = canvas.getContext('2d');
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
    game.drawHub(player);
    alert("gameHub worked");
    bullets = array();
    parachutes = array();

}

//***defining parachute and bullet objects***//
function bullet(Slope, PosX, PosY) {
    var slope = Slope;
    var posX = PosX;
    var posY = PosY;
}

function parachute(Index, PosX, PosY) {
    var index = Index;
    var posX = PosX;
    var posY = PosY;
}

//***canvas gameboard***//
function GameBoard() {

    this.drawHub = function (player) {
        switch (player) {
            case 'one':
                ctx.fillStyle = 'red';
                ctx.strokeStyle = '#5B2701';
                break;
            case 'two':
                ctx.fillStyle = 'blue';
                ctx.strokeStyle = '#01125B';
                break;
        }
        alert("color, hub worked");
        ctx.beginPath();
        ctx.arc(325, 150, 50, 0, Math.PI, true);
        ctx.closePath();
        ctx.lineWidth = 5;
        ctx.fill();
        ctx.stroke();
    }

    this.drawElement = function (xpos, ypos) {
        ctx.beginPath();
        ctx.moveTo(xpos, ypos);
        ctx.lineTo(xpos + 3, ypos + 7);
        ctx.stroke();
    };

    this.clearBoard = function () {
        context.clearRect(0, 0, canvas.width, canvas.height);
    };
}

//***Event Listeners***//
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