 //***variable declarations***//
//See This: http://jlongster.com/Making-Sprite-based-Games-with-Canvas
var ctx;
var background;
var lastTime;

//Game Dimensions
var gameY;
var gameX;

window.onload = function() {
    //credit where credit is due:http://stackoverflow.com/questions/6796194/canvas-getcontext2d-returns-null
    var canvas = document.getElementById('frame');    
    gameX=document.getElementById("game").clientWidth;
    gameY=document.getElementById("game").clientHeight;
    alert(gameY + ":" + gameX);
    
    loadListeners();
    var canvas = document.createElement('canvas');
    ctx = canvas.getContext('2d');
    loadListeners();

    canvas.width = gameX;
    canvas.height = gameY;
    canvas.setAttribute('id', 'frame');
    document.('#game').appendChild(canvas);
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
    bullets = [];
    parachutes = [];
    gameListeners();
    
    reset();
    lastTime = Date.now();
    main();

}

function nextLvl() {
   level++;
   paraMax = level * 15;
}

// Game over
function gameOver() {
    document.getElementById('game-over').style.display = 'block';
    document.getElementById('game-over-overlay').style.display = 'block';
    isGameOver = true;
}

// Reset game to original state
function reset() {
    document.getElementById('game-over').style.display = 'none';
    document.getElementById('game-over-overlay').style.display = 'none';
    isGameOver = false;
    gameTime = 0;
    score = 0;

    enemies = [];
    bullets = [];

    player.pos = [50, canvas.height / 2];
};

function main() {
    var now = Date.now();
    var dt = (now - lastTime) / 1000.0;

    update(dt);
    render();

    lastTime = now;
    requestAnimFrame(main);
};

function update(dt) {
    gameTime += dt;

    updateEntities(dt);

    // It gets harder over time by adding enemies using this
    // equation: 1-.993^gameTime
    if(Math.random() < 1 - Math.pow(.993, gameTime)) {
        enemies.push({
            pos: [Math.random() * (canvas.width - 4),
                  canvas.height],
            sprite: new Sprite('img/sprites.png', [0, 78], [80, 39],
                               6, [0, 1, 2, 3, 2, 1])
        });
    }

    checkCollisions();

    scoreEl.innerHTML = score;
};

function updateEntities(dt) {
    // Update the player sprite animation
    player.sprite.update(dt);

    // Update all the bullets
    for(var i=0; i<bullets.length; i++) {
        var bullet = bullets[i];

        switch(bullet.dir) {
        case 'up': bullet.pos[1] -= bulletSpeed * dt; break;
        case 'down': bullet.pos[1] += bulletSpeed * dt; break;
        default:
            bullet.pos[0] += bulletSpeed * dt;
        }

        // Remove the bullet if it goes offscreen
        if(bullet.pos[1] < 0 || bullet.pos[1] > canvas.height ||
           bullet.pos[0] > canvas.width) {
            bullets.splice(i, 1);
            i--;
        }
    }

    // Update all the enemies
    for(var i=0; i<enemies.length; i++) {
        enemies[i].pos[0] -= enemySpeed * dt;
        enemies[i].sprite.update(dt);

        // Remove if offscreen
        if(enemies[i].pos[0] + enemies[i].sprite.size[0] < 0) {
            enemies.splice(i, 1);
            i--;
        }
    }

    // Update all the explosions
    for(var i=0; i<explosions.length; i++) {
        explosions[i].sprite.update(dt);

        // Remove if animation is done
        if(explosions[i].sprite.done) {
            explosions.splice(i, 1);
            i--;
        }
    }
}

//***various functions or helpers***//

function slope(x, y) {
	 var xFinal=gameX-x;
	 var yFinal=gameY-y;
	 
	 var slope=Math.round(yFinal/xFinal);
	 return slope;
}

// A cross-browser requestAnimationFrame
// See https://hacks.mozilla.org/2011/08/animating-with-javascript-from-setinterval-to-requestanimationframe/
var requestAnimFrame = (function(){
    return window.requestAnimationFrame       ||
        window.webkitRequestAnimationFrame ||
        window.mozRequestAnimationFrame    ||
        window.oRequestAnimationFrame      ||
        window.msRequestAnimationFrame     ||
        function(callback){
            window.setTimeout(callback, 1000 / 60);
        };
})();

function collides(x, y, r, b, x2, y2, r2, b2) {
    return !(r <= x2 || x > r2 ||
             b <= y2 || y > b2);
}

function boxCollides(pos, size, pos2, size2) {
    return collides(pos[0], pos[1],
                    pos[0] + size[0], pos[1] + size[1],
                    pos2[0], pos2[1],
                    pos2[0] + size2[0], pos2[1] + size2[1]);
}

function checkCollisions() {
    checkPlayerBounds();

    // Run collision detection for all enemies and bullets
    for(var i=0; i<enemies.length; i++) {
        var pos = enemies[i].pos;
        var size = enemies[i].sprite.size;

        for(var j=0; j<bullets.length; j++) {
            var pos2 = bullets[j].pos;
            var size2 = bullets[j].sprite.size;

            if(boxCollides(pos, size, pos2, size2)) {
                // Remove the enemy
                enemies.splice(i, 1);
                i--;

                // Add score
                score += 100;

                // Add an explosion
                explosions.push({
                    pos: pos,
                    sprite: new Sprite('img/sprites.png',
                                       [0, 117],
                                       [39, 39],
                                       16,
                                       [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12],
                                       null,
                                       true)
                });

                // Remove the bullet and stop this iteration
                bullets.splice(j, 1);
                break;
            }
        }

        if(boxCollides(pos, size, player.pos, player.sprite.size)) {
            gameOver();
        }
    }
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

    // Draw everything
    this.render= function() {
        ctx.fillStyle = terrainPattern;
        ctx.fillRect(0, 0, canvas.width, canvas.height);

        // Render the player if the game isn't over
        if(!isGameOver) {
            this.renderEntity(player);
        }

        this.renderEntities(bullets);
        this.renderEntities(enemies);
        this.renderEntities(explosions);
    };

    this.renderEntities = function(list) {
        for(var i=0; i<list.length; i++) {
            this.renderEntity(list[i]);
        }    
    }

    this.renderEntity = function(entity) {
        ctx.save();
        ctx.translate(entity.pos[0], entity.pos[1]);
        entity.sprite.render(ctx);
        ctx.restore();
    }    
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