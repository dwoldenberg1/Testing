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
  	<div class="main-wrapper">
  		<div class="right-main-wrapper" id="test"> 
          <a href="/Testing/phpframeworks/CodeIgniter_2/index.php/game/validate/" + <?php echo $previous ?> + "' " id="login">
    			<b>Login to an Existing Account</b> <br> <div style="text-align: center;">or</div> <b>Create a new Account</b>
    		</a>
    	</div>
        <a <?php echo " href= '/Testing/phpframeworks/CodeIgniter_2/index.php/pages/view/".$previous. "' " ?> class="back">Back</a>
    </div>  
    <div id="game-over-overlay">
    </div>
    <!--<a <?php echo " href= '/Testing/phpframeworks/CodeIgniter_2/index.php/pages/view/".$previous. "' " ?> class="back">Back</a>

    <a href="#" class="login">
    	<b>Login to an Existing Account</b> <br> or <br> <b>Create a new Account</b>
    </a> -->
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
      <div id="overallScore"><b><?php echo $bestUser?></b> is the user with the highest score of <b><?php echo $bestScore?></b>!</div>
      <a href="leaderboard">CLick here to view the full leaderboard</a>
    </div>
    <div id="data">
    	<div id="scoreTest" style="display: none;">0</div>
    	<div id="highestscore" style="display: none;"></div>
  		<div id="previous" style="display: none;"><?php echo $previous ?></div>
    </div>

    <script type="text/javascript" src="/Testing/phpframeworks/CodeIgniter_2/assets/js/app/resources.js"></script>
    <script type="text/javascript" src="/Testing/phpframeworks/CodeIgniter_2/assets/js/app/input.js"></script>
    <script type="text/javascript" src="/Testing/phpframeworks/CodeIgniter_2/assets/js/app/sprite.js"></script>
    <script type="text/javascript" src="/Testing/phpframeworks/CodeIgniter_2/assets/js/app/app.js"></script>
    <script>
	    if (<?php echo $logged_in ?> == true)
	    {
		    var user="<?php echo ($username) ?>";
		    var highscore="<?php echo ($highscore) ?>";
		    var previous="<?php echo $previous ?>";
		    $('#test').html('<a href="/Testing/phpframeworks/CodeIgniter_2/index.php/game/validate/" + <?php echo $previous ?> + " " id="login"> You are logged in as: <b> <div id="username" style="display:inline;">' + user + '</div> </b> <br> Highscore: <b> <div id="highscore" style="display:inline;">' + highscore + '</div> </b> <br> </a');
		    $('#test').append('<a href="/Testing/phpframeworks/CodeIgniter_2/index.php/game/logout">Logout</a>');
		    $('#scoreTest').html('1');
	    }
    </script>
  </body>
</html>