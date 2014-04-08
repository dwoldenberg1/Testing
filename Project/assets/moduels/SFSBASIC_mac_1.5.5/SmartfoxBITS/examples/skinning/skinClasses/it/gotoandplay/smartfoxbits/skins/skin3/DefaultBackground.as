import com.metaliq.skins.BaseBackground
import it.gotoandplay.smartfoxbits.utils.Draw

class it.gotoandplay.smartfoxbits.skins.skin3.DefaultBackground extends BaseBackground
{
	
	private var focusBorder:MovieClip

	function InsetBackground()
	{
		
	}

	private function draw():Void
	{
		var h:Number = __height
		var w:Number = __width
		var m:Object = {matrixType:"box", x:0, y:0, w:1, h:h, r:90/180*Math.PI}
		
		clear()
		
		beginFill(0x0F4756, 100)
		lineStyle(2, 0xFFFFFF, 100)
		Draw.roundRectangle(this, 0, 0, w, h, 6)
		endFill()
		
		if (focused)
		{
			var b:MovieClip = createEmptyMovieClip("focusBorder", 1000)
			b.lineStyle(0, 0xFFFFFF, 100)
			Draw.roundRectangle(b, -2, -2, w+4, h+4, 6)
		}
		else
			focusBorder.removeMovieClip()
	}
}
