<div id="main">
<!-- Font and paired font of .heading/.subheading and body from Google Fonts -->
    <!-- www.google.com/fonts/specimen/Ubuntu -->
    <!-- www.google.com/fonts/specimen/Ubuntu#pairings -->
    <div class="row-fluid heading">
      <div class="span12">
        <h1 >About</h1>
      </div>
    </div>
    
    <div class="row-fluid subheading">
      <div class="span12">
        <!-- Special typography from Bootstrap for lead paragraph. -->
        <!-- http://twitter.github.io/bootstrap/base-css.html#typography -->
        <p class="lead">Find out what it's all about:</p>
      </div>
    </div>
    
    </div>

    <!-- For the FAQ, we introduce a little bit of JS, using the accordion. -->
    <!-- This brings in jquery.js and bootstrap.js as dependencies. -->
    <!-- http://twitter.github.io/bootstrap/javascript.html#collapse -->
    <div class="row-fluid faq">
      <div class="span10 offset1">
        <div class="accordion" id="accordion2">
          <div class="accordion-group">
            <div class="accordion-heading">
              <a class="accordion-toggle" data-toggle="collapse" data-parent="#accordion2" href="#collapseOne">
                    What is this website?
                  </a>
            </div>
            <div id="collapseOne" class="accordion-body collapse">
              <div class="accordion-inner">
                A testing space for various projects of mine. The initial launch just contains the game I've been working on and some server-side systems that I am testing out.
              </div>
            </div>
          </div>
          <div class="accordion-group">
            <div class="accordion-heading">
              <a class="accordion-toggle" data-toggle="collapse" data-parent="#accordion2" href="#collapseTwo">
                    Why did you make the website?
                  </a>
            </div>
            <div id="collapseTwo" class="accordion-body collapse">
              <div class="accordion-inner">
                It started as a project for my Design and Data Structures class, but has developed into more that that. I may upload more games or I may not, depends on what I feel like working on.
              </div>
            </div>
          </div>
          <div class="accordion-group">
            <div class="accordion-heading">
              <a class="accordion-toggle" data-toggle="collapse" data-parent="#accordion2" href="#collapseThree">
                    What sparked your interest in programmming?
                  </a>
            </div>
            <div id="collapseThree" class="accordion-body collapse">
              <div class="accordion-inner">
                I started learning Java in 2010 and from there took a few more classes in it, developing my knowledge of both OOP programming and solving problems with Algorithms. From there I began to learn Web development with HTML 5, CSS 3, and php. In the future, I plan on learning Ruby on Rails, python, and Objective C.</div>
            </div>
          </div>
        </div>
      </div>

    </div>

</div>