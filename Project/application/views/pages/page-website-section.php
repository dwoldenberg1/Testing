<div class="website-section section pop">
<!--
	<div id="about-construction">
		<h2>Under Construction...</h2>
	</div>
-->
	<div class="countdown">
		<div class="number">
	</div>
<!--
	<article>
		<div id="image-me" class="image1 left">
			<img id="me" src="<?php echo get_template_directory_uri(); ?>/images/me.jpg" />
			<p class="credit">Photo by Charlie Andrews</p>
		</div>
		<div class="text right">
			<h1>Austin Chan</h1>
			<p>Austin serves as the sole developer and co-designer of this site.</p>
		</div>
		<div class="clear"></div>
	</article>
	<article>
		<div class="text left">
			<h1>David Lim</h1>
			<p>In addition to being Editor-In-Chief, David is the co-designer of this site with Austin.</p>
			<p>But unfortunately, we don't have any pictures of David.  So here is someone else.</p>
		</div>
		<div class="image1 right">
			<img id="me" src="<?php echo get_template_directory_uri(); ?>/images/saj.png" />
			<p class="credit">At least it's not Syd Foreman.</p>
		</div>
		<div class="clear"></div>
	</article>
-->
	<?php 
	if(have_posts()){
		the_post();
		$wp_query->in_the_loop = true;
		the_content();
	}
	?>
	<p id="edit-single-article"><?php edit_post_link('Edit this entry','',''); ?></p>
</div>
<script>

</script>
<style>
.section a{
	display:inline;
}
</style>