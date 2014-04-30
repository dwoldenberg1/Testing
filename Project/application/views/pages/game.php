<!DOCTYPE html>
<html>
  <head>
    <meta charset="utf-8">

    <title></title>
    <meta name="description" content="">
    <meta name="viewport" content="width=device-width">

    <link rel="stylesheet" href="/Testing/phpframeworks/CodeIgniter_2/assets/css/app.css">
  </head>
  <body>    
    <div id="game-over-overlay">
    </div>
    <a <?php echo " href= '/Testing/phpframeworks/CodeIgniter_2/index.php/pages/view/".$previous. "' " ?> class="back">Back</a>

    <div id="game-over">
      <h1>GAME OVER</h1>
      <button id="play-again">Play Again</button>
    </div>

    <div class="wrapper">
      <div id="instructions">
        <div>
          move with <span class="key">arrows</span> or <span class="key">wasd</span>
        </div>
        <div>
          shoot with <span class="key">space</span>
        </div>
      </div>

      <div id="score"></div>
    </div>

    <script type="text/javascript" src="/Testing/phpframeworks/CodeIgniter_2/assets/js/app/resources.js"></script>
    <script type="text/javascript" src="/Testing/phpframeworks/CodeIgniter_2/assets/js/app/input.js"></script>
    <script type="text/javascript" src="/Testing/phpframeworks/CodeIgniter_2/assets/js/app/sprite.js"></script>
    <script type="text/javascript" src="/Testing/phpframeworks/CodeIgniter_2/assets/js/app/app.js"></script>
  </body>
</html>