import com.metaliq.skins.BaseBackground
import it.gotoandplay.smartfoxbits.utils.Draw

class it.gotoandplay.smartfoxbits.skins.skin3.ButtonBackground extends BaseBackground
{
	private var highlight:MovieClip
	private var focusBorder:MovieClip

	function ButtonBackground()
	{
		state = "trueUp"
		setSize(100, 22)
	}

	function draw():Void
	{
		var h:Number = __height
		var w:Number = __width
		var matrix:Object = {matrixType:"box", x:0, y:0, w:1, h:h, r:90/180*Math.PI}
		
		clear()
		highlight.removeMovieClip()
		
		switch (state)
		{
			case "falseUp" :
				drawFalseState(w, h, matrix)
				break
			case "falseOver" :
				drawFalseState(w, h, matrix)
				setHighlight(w, h)
				break
			case "falseDown" :
				drawFalseState(w, h, matrix)
				setDim(w, h)
				break
			case "falseDisabled" :
				drawFalseState(w, h, matrix) // Disabled state should be improved, to make it differ from the Up state
				break
			case "trueUp" :
				drawTrueState(w, h, matrix)
				break
			case "trueOver" :
				drawTrueState(w, h, matrix)
				setHighlight(w, h)
				break
			case "trueDown" :
				drawTrueState(w, h, matrix)
				setDim(w, h)
				break;
			case "trueDisabled" :
				drawTrueState(w, h, matrix)
				break
		}
		
		if (focused)
		{
			var b:MovieClip = createEmptyMovieClip("focusBorder", 1000)
			b.lineStyle(0, 0xFFFFFF, 100)
			Draw.roundRectangle(b, -2, -2, w+4, h+4, 6)
		}
		else
			focusBorder.removeMovieClip()
	}
	
	private function drawFalseState(w, h, m)
	{
		beginGradientFill("linear", [0x0F4756, 0xFFFFFF, 0x0F4756], [100, 50, 100], [0, 30, 100], m)
		lineStyle(2, 0xFFFFFF, 100)
		Draw.roundRectangle(this, 0, 0, w, h, 6)
		endFill()
	}
	
	private function drawTrueState(w, h, m)
	{
		beginGradientFill("linear", [0xDCDCDC, 0xBEBEBE, 0xEBEBEB], [100, 100, 100], [0, 30, 100], m)
		lineStyle(2, 0xFFFFFF, 100)
		Draw.roundRectangle(this, 0, 0, w, h, 6)
		endFill()
	}
	
	private function setHighlight(w, h)
	{
		createEmptyMovieClip("highlight", 1)
		highlight.beginFill(0x1881A1, 20)
		highlight.lineStyle(2, 0xFFFFFF, 100)
		Draw.roundRectangle(highlight, 0, 0, w, h, 6)
		highlight.endFill()
	}
	
	private function setDim(w, h)
	{
		createEmptyMovieClip("highlight", 1)
		highlight.beginFill(0x1881A1, 50)
		highlight.lineStyle(2, 0xFFFFFF, 100)
		Draw.roundRectangle(highlight, 0, 0, w, h, 6)
		highlight.endFill()
	}
	
	
}
