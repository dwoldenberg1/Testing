import com.metaliq.skins.BaseBackground
import it.gotoandplay.smartfoxbits.utils.Draw

class it.gotoandplay.smartfoxbits.skins.vegetabled.PanelBackground extends BaseBackground
{
	// ui elements:
	private var focusBorder:MovieClip

	function PanelBackground()
	{
		
	}

	private function draw():Void
	{
		clear()
		
		// White semi-transparent background
		this.beginFill(0xFFFFFF, 85)
		this.lineStyle(0, 0xFFFFFF, 0)
		Draw.roundRectangle(this, -2, -2, __width + 2, __height + 2, 10)
		this.endFill()
		
		if (state != "disabled")
		{
			// Yellow gradient fill (if component is not disabled)
			var matrix:Object = {matrixType:"box", x:0, y:__height/2, w:__width, h:__height, r:90/180*Math.PI}
			this.beginGradientFill("linear", [0xFFFFFF,0xFFFF33], [0,100], [0,127], matrix)
		}
		else
			// Gray background (if component is disabled)
			this.beginFill(0xCCCCCC, 30)
		
		this.lineStyle(0, 0xFFFFFF, 0)
		Draw.roundRectangle(this, -2, -2, __width + 2, __height + 2, 10)
		this.endFill()
		
		// Gray shadow
		this.lineStyle(0, 0x125439, 0)
		this.beginFill(0x125439, 16)
		Draw.roundRectangle(this, 6, 4, __width - 13, __height - 10, 10)
		Draw.roundRectangle(this, -2, -2, __width + 2, __height + 2, 10)
		this.endFill()
		
		// Green border
		this.lineStyle(4, 0x83C11E, 100)
		Draw.roundRectangle(this, -2, -2, __width + 2, __height + 2, 10)
		
		// Draw focus border
		if (focused)
		{
			var b:MovieClip = createEmptyMovieClip("focusBorder", 1000)
			b.lineStyle(2,0x125439, 50)
			Draw.roundRectangle(b, -2, -2, __width + 2, __height + 2, 10)
		}
		else
		{
			focusBorder.removeMovieClip()
		}
	}
}
