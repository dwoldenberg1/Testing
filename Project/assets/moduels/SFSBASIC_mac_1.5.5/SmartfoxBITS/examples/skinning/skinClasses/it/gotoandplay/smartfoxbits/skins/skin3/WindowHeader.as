import com.metaliq.controls.BaseButton
import it.gotoandplay.smartfoxbits.utils.Draw

class it.gotoandplay.smartfoxbits.skins.skin3.WindowHeader extends BaseButton
{
	private var headerOwner // injected from window.
	private var __iconID:String

	// Initialization
	private function WindowBackground()
	{
		
	}
	
	public function setIcon(p_icon:String):Void
	{
		iconClip.removeMovieClip()
		attachMovie(p_icon, "iconClip", 101, {_visible: false})
		__iconID = p_icon
		iconWidth = (iconClip._width == undefined) ? 0 : iconClip._width
		iconHeight = (iconClip._height == undefined) ? 0 : iconClip._height
		doLater("draw")
	}
	
	private function draw():Void
	{
		var h:Number = __height
		var w:Number = __width
		var m:Object = {matrixType:"box", x:0, y:__height/2, w:__width, h:__height, r:90/180*Math.PI}
		
		clear()
		
		beginGradientFill("linear", [0x9FD8E9,0x37AFD1], [100,100], [0,127], m)
		lineStyle(0, 0xFFFFFF, 0)
		Draw.topRoundRectangle(this, 8, 8, w - 16, h, 10)
		endFill()
		
		// Set icon and label
		iconClip._x = 5 + 6
		iconClip._y = Math.round(h/2 - iconHeight/2) + 6
		
		if (__label.embedFonts != embedFonts)
			__label.embedFonts = embedFonts
		
		var tPad:Number = (iconWidth == 0) ? 0 : textPadding
		
		__label.autoSize = "left"
		__label._x = (__iconID != undefined) ? (iconClip._x + iconWidth + 3) : (5 + 6)
		
		var labelWidth:Number = (__label == undefined) ? 4 : __label.textWidth + 4
		var labelHeight:Number = (__label == undefined) ? 0 : __label._height = __label.textHeight + 4
		var availableWidth:Number = (w - headerOwner.headerRightMargin - __label._x) - (5 + 6)
		
		__label.autoSize = "none"
		__label._width = Math.min(Math.min(labelWidth, w - iconWidth - tPad), availableWidth)
		__label._y = Math.round(height/2 - labelHeight/2) + 6
		
		iconClip._visible = true
	}
}