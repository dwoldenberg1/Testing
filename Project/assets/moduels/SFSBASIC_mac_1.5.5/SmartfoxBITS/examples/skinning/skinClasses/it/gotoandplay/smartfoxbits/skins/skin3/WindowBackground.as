import com.metaliq.skins.BaseBackground
import it.gotoandplay.smartfoxbits.utils.Draw

class it.gotoandplay.smartfoxbits.skins.skin3.WindowBackground extends BaseBackground
{
	// Initialization:
	private function WindowBackground()
	{
		
	}
	
	private function draw():Void
	{		
		var h:Number = __height
		var w:Number = __width
		var matrix:Object = {matrixType:"box", x:0, y:0, w:__width, h:__height, r:90/180*Math.PI}
		
		clear()
		
		this.beginGradientFill("linear", [0x14A1CC,0x1881A1], [100,100], [0,255], matrix);
		this.lineStyle(0, 0xFFFFFF, 0)
		Draw.roundRectangle(this, 6, 6, __width - 12, __height - 12, 10)
		this.endFill()
		
		this.lineStyle(1, 0x666666, 100)
		this.beginGradientFill("linear", [0xFFFFFF,0xCCCCCC], [100,100], [0,255], matrix)
		
		Draw.roundRectangle(this, 0, 0, __width, __height, 10)
		this.lineStyle(1, 0x027395, 100)
		Draw.roundRectangle(this, 6, 6, __width - 12, __height - 12, 10)
		this.endFill()
	}
}