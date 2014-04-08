
// [flashAPI].mx easing
//
// it's part of [flashAPI] project
// http://flashAPI.yestoall.com
//
// [03.01.30] nacho@yestoall.com

// based in roberpenner easing equations funtions
// www.robertpenner.com

/*

	* needs "easingEquations.as" to work

	methods :
		easingTo(equation,type,x,y,duration);
		-> easing equation movement to (x,y) absolute coordinates
			equation : Quad, Cubic, Quart, Quint, Sine, Expo, Circ
			type : In, Out, InOut

		easingBy(equation,type,x,y,duration);
		-> easing equation movement to (x,y) relative coordinates
		
		easingStop();
		-> stop movement
			
	events :
		onEasing(x,y)
		-> in every loop of movement
		
		onEasingEnd()
		-> at the end of movement
		
	examples :
		mc1.easingTo("Sine","InOut",100,100,20);
		-> easing Sine equation (InOut type) to (100,100) absotule coordinates in 20 frames
		
*/

MovieClip.prototype.easingTo = function(equation,type,x,y,duration,interval) 
{
	this.easingBy(equation,type,x-this._x,y-this._y,duration);
}

MovieClip.prototype.easingBy = function(equation,type,x,y,duration,interval) 
{	
	if (this.easingActive) clearInterval(this.easingThread);

	this.easingActive = true;
	
	this.easingData = 
	{
		equation : equation,
		type : type,
		Xini : this._x,
		Yini : this._y,
		Xend : (x!=null) ? x : this._x,
		Yend : (y!=null) ? y : this._y,
		duration : duration || 10,
		interval : interval || 10,
		counter : 0
	}
	
	this.easingThread = setInterval(this,"easingLoop",this.easingData.interval);
}

MovieClip.prototype.easingStop = function() 
{
	if (!this.easingActive) return;
	clearInterval(this.easingThread);
	this.easingActive = false;
}

MovieClip.prototype.easingLoop = function() 
{
	this.easingData.counter++;
	var d = this.easingData;

	if (d.counter <= d.duration) 
	{
		var x = eval("MathObj.ease"+d.type+d.equation)(d.counter, d.Xini, d.Xend, d.duration);
		var y = eval("MathObj.ease"+d.type+d.equation)(d.counter, d.Yini, d.Yend, d.duration);
		
		this._x = x;
		this._y = y;
		this.onEasing(x,y);
	}
	else
	{
		this.easingStop();
		this.onEasingEnd();
	}
}

