/*
	SmartFoxServer Client API -- Room Object
	Actionscript 2.0
	
	version 2.6
	
	Last update: December 29, 2004
*/

class it.gotoandplay.smartfoxserver.User
{
	private var id:Number
	private var name:String
	private var variables:Object
	private var isSpec:Boolean
	private var isMod:Boolean
	private var pid:Number
	
	function User(id, name)
	{
		this.id = id
		this.name = name
		this.variables = new Object()
		this.isSpec = false
	}
	
	public function getId():Number
	{
		return this.id
	}
	
	public function getName():String
	{
		return this.name
	}
	
	public function getVariable(varName:String)
	{
		return this.variables[varName]
	}
	
	public function getVariables():Object
	{
		return this.variables
	}
	
	public function setIsSpectator(b:Boolean)
	{
		this.isSpec = b
	}
	
	public function isSpectator():Boolean
	{
		return this.isSpec
	}
	
	public function setModerator(b:Boolean)
	{
		this.isMod = b
	}
	
	public function isModerator():Boolean
	{
		return this.isMod
	}
	
	public function getPlayerId():Number
	{
		return this.pid
	}
	
	public function setPlayerId(pid:Number):Void
	{
		this.pid = pid
	}
	
}