<?php foreach ($news as $news_item): ?>

    <h2><?php echo $news_item['title'] ?></h2>
    <div id="main">
        <?php echo $news_item['text'] ?>
    </div>
    <p><a <?php echo "href=/Testing/phpframeworks/CodeIgniter_2/index.php/news/view/".$news_item['slug'] ?> >View article</a></p>

<?php endforeach ?>