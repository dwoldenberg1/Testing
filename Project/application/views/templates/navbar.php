<!DOCTYPE html>
<!--https://github.com/EllisLab/CodeIgniter/wiki/Asset-Helper, http://stackoverflow.com/questions/18690045/how-to-properly-add-a-navbar-at-the-top-of-the-page-using-codeignitor-bootstrap -->

	   <div class="navbar navbar-inverse navbar-fixed-top">
    <div class="navbar-inner">
      <div class="container">
        <button type="button" class="btn btn-navbar" data-toggle="collapse" data-target=".nav-collapse">
          <span class="icon-bar"></span>
          <span class="icon-bar"></span>
          <span class="icon-bar"></span>
        </button>
        <a class="brand" href="/Testing/phpframeworks/CodeIgniter_2/" >David Woldenberg</a>
        <div class="nav-collapse collapse">
          <ul class="nav" >
            <li <?php if($title==="Home")echo"class='active'";?>><a href="/Testing/phpframeworks/CodeIgniter_2/">Home</a>
            </li>
            <li <?php if($title==="About")echo"class='active'";?>><a href="/Testing/phpframeworks/CodeIgniter_2/index.php/about" >About</a>
            </li>
            <li <?php if($title==="Game")echo"class='active'";?>><a href="#Game" >Game</a>
            </li>
            <li <?php if($title==="Contact")echo"class='active'";?>><a href="#Contact" ">Contact</a>
            </li>
          </ul>
        </div>
      </div>
    </div>
	   </div>
        <!--/.nav-collapse -->