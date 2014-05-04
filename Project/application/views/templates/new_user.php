<h2>Create an account</h2>

<?php echo validation_errors(); ?>

<?php echo form_open('game/new_user') ?>

	<label for="user">Username</label>
	<input type="input" name="user"><br />

	<label for="pass">Password</label>
	<input type="input" name="pass"><br />
	
	<label for="email">Email</label>
	<input type="input" name="email"><br />


	<input type="submit" name="submit" value="Create an account" />

</form>