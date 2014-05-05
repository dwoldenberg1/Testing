<h2>Create a news item</h2>

<?php echo validation_errors(); ?>

<?php echo form_open('game/prompt_login') ?> <!--form_open()=<form method="post" accept-charset="utf-8" action="http:/example.com/index.php/game/prompt_login" />-->

	<label for="user">Username</label>
	<input type="input" name="user" /><br />

	<label for="pass">Password</label>
	<input type="input" name="user" /><br />

	<input type="submit" name="submit" value="Login" />

</form>
<p></p>
<a href="/Testing/phpframeworks/CodeIgniter_2/index.php/game/new_user" class="create-Account"><b>Create a New Account</b></a>