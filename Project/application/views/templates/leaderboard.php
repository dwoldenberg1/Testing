<table class="reference" style="width:100%">
	<tbody><tr>
		<tbody><tr>
		<th>Rank</th>
		<th>Username</th>		
		<th>Highscore</th>
	</tr>
		<?php for ($x =0; $x<2; $x++): ?>
			<tr>
			    <td><?php $user=$users[$x]; echo $x + 1; ?>.</td>
			    <td><?php echo $user['username'] ?></td>
			    <td><?php echo $user['highscore'] ?></td>
			</tr>
		<?php endfor; ?>
	</tbody>
</table>