
<body style="height: 375px; padding-top: 10px; padding-left: 10px;">
<a <?php echo " href= '/Testing/phpframeworks/CodeIgniter_2/index.php/pages/view/".$previous. "' " ?> class="back">Back</a>

<div id="spin" ></div>

<div id="game">
	<canvas id="frame"></canvas>
	<div class="options">
			<div id="singleplaer" style="visibility: none;" onclick="start(singleplayer)">Singleplayer</div>
			<div id="multiplayer" style="visibility: none;" onclick="start(multiplayer)">Multiplayer</div>
		</div>
	<div id="board">
		<div id="player1"></div>
		<div id="player2"></div>
		<div id="scores"></div>
	</div>
</div>