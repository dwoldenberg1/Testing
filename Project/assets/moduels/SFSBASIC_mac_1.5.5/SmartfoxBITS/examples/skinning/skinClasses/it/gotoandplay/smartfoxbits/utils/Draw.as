class it.gotoandplay.smartfoxbits.utils.Draw
{
	private function Draw()
	{
		
	}
	
	static function roundRectangle(mc, x, y, w, h, cornerRadius):Void
	{
		if (arguments.length < 4)
		{
			return;
		}
		
		if (cornerRadius > 0)
		{
			var r:Number = Math.min(Math.abs(cornerRadius), Math.min(Math.abs(w), Math.abs(h))/2);
			var f:Number = 0.707106781186548*r;
			var a:Number = 0.588186525863094*r;
			var b:Number = 0.00579432557070009*r;
			var ux:Number = Math.min(x, x+w);
			var uy:Number = Math.min(y, y+h);
			var lx:Number = Math.max(x, x+w);
			var ly:Number = Math.max(y, y+h);
			mc.moveTo(ux+r, uy);
			var cx:Number = lx-r;
			var cy:Number = uy+r;
			mc.curveTo(cx, uy, cx, uy);
			mc.curveTo(lx-a, uy+b, cx+f, cy-f);
			mc.curveTo(lx-b, uy+a, lx, uy+r);
			cy = ly-r;
			mc.curveTo(lx, cy, lx, cy);
			mc.curveTo(lx-b, ly-a, cx+f, cy+f);
			mc.curveTo(lx-a, ly-b, lx-r, ly);
			cx = ux+r;
			mc.curveTo(cx, ly, cx, ly);
			mc.curveTo(ux+a, ly-b, cx-f, cy+f);
			mc.curveTo(ux-b, ly-a, ux, ly-r);
			cy = uy+r;
			mc.curveTo(ux, cy, ux, cy);
			mc.curveTo(ux+b, uy+a, cx-f, cy-f);
			mc.curveTo(ux+a, uy+b, ux+r, uy);
		}
		else
		{
			mc.moveTo(x, y);
			mc.lineTo(x+w, y);
			mc.lineTo(x+w, y+h);
			mc.lineTo(x, y+h);
			mc.lineTo(x, y);
		}
	}
	
	static function topRoundRectangle(mc, x, y, w, h, cornerRadius):Void
	{
		if (arguments.length < 4)
		{
			return;
		}
		
		if (cornerRadius > 0)
		{
			var r:Number = Math.min(Math.abs(cornerRadius), Math.min(Math.abs(w), Math.abs(h))/2);
			var f:Number = 0.707106781186548*r;
			var a:Number = 0.588186525863094*r;
			var b:Number = 0.00579432557070009*r;
			var ux:Number = Math.min(x, x+w);
			var uy:Number = Math.min(y, y+h);
			var lx:Number = Math.max(x, x+w);
			var ly:Number = Math.max(y, y+h);
			mc.moveTo(ux+r, uy);
			var cx:Number = lx-r;
			var cy:Number = uy+r;
			mc.curveTo(cx, uy, cx, uy);
			mc.curveTo(lx-a, uy+b, cx+f, cy-f);
			mc.curveTo(lx-b, uy+a, lx, uy+r);
			cy = ly-r;
			mc.lineTo(x+w,y+h);
			mc.lineTo(x,y+h);
			cx = ux+r;
			cy = uy+r;
			mc.curveTo(ux, cy, ux, cy);
			mc.curveTo(ux+b, uy+a, cx-f, cy-f);
			mc.curveTo(ux+a, uy+b, ux+r, uy);
		}
		else
		{
			mc.moveTo(x, y);
			mc.lineTo(x+w, y);
			mc.lineTo(x+w, y+h);
			mc.lineTo(x, y+h);
			mc.lineTo(x, y);
		}
	}
}