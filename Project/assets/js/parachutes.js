//***variable declarations***//

var level = 1;

var bullet;
var parachuets;

var MultiPlayer = false;
var canvas = document.getElementById('frame');
var ctx = canvas.getContext('2d');
var game = GameBoard();

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

function start() {
    game.drawHub(player);
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
                    context.fillStyle = 'red';
                    context.strokeStyle = '#5B2701';
                    break;
                case 'two':
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
    document.getElementById('singleplayer').addEventListener('click', start('one'), false);
    document.getElementById('multiplayer').addEventListener('click', start('two'), false);