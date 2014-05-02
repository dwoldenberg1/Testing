<h2>Create a news item</h2>

<?php echo validation_errors(); ?>

<?php echo form_open('game/prompt_login') ?>

	<label for="user">Username</label>
	<input type="input" name="user" /><br />

	<label for="pass">Password</label>
	<input type="input" name="user" /><br />

	<input type="submit" name="submit" value="Login" />

</form>

//NEEED TOO FIX THIS