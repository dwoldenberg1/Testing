/**
	SmartFoxClient API
	Actionscript 2.0 Client API

	ver 1.4.0 -- April 6th, 2007
	
	Supports Flash Compiler and MTASC Actionscript compiler
	
	(c) gotoAndPlay 2004-2007
	www.gotoandplay.it
	www.smartfoxserver.com
*/

class it.gotoandplay.smartfoxserver.SmartFoxClient extends XMLSocket
{
	public static var MODMSG_TO_USER:String = "u"
	public static var MODMSG_TO_ROOM:String = "r"
	public static var MODMSG_TO_ZONE:String = "z"
	
	public static var PROTOCOL_XML:String = "xml"
	public static var PROTOCOL_STR:String = "str"
	public static var PROTOCOL_JSON:String = "json"

	private var objRef:Object
	private var t1:Number, t2:Number
	private var isConnected:Boolean
	private var changingRoom:Boolean
	private var ipAddress:String
	private var portNumber:Number
	public var httpPort:Number = 8080
	
	private var majVersion:Number = 1
	private var minVersion:Number = 4
	private var subVersion:Number = 0
	
	private var arrayTags:Object
	private var messageHandlers:Object
	private var os:it.gotoandplay.smartfoxserver.ObjectSerializer

	public var roomList:Object
	public var buddyList:Array
	public var buddyVars:Array
	public var activeRoomId:Number
	public var myUserId:Number
	public var myUserName:String
	public var debug:Boolean
	public var playerId:Number
	public var amIModerator:Boolean
	public var rawProtocolSeparator:String = "%"
	
	//public var evtHandler:Object
	
	// Event handlers methods
	public var onConnectionLost:Function
	public var onCreateRoomError:Function
	private var onConnect:Function
	public var onConnection:Function
	public var onJoinRoom:Function
	public var onJoinRoomError:Function
	public var onLogin:Function
	public var onLogout:Function
	public var onObjectReceived:Function
	public var onPublicMessage:Function
	public var onPrivateMessage:Function
	public var onAdminMessage:Function
	public var onModeratorMessage:Function
	public var onRoomAdded:Function
	public var onRoomDeleted:Function
	public var onRoomLeft:Function
	public var onRoomListUpdate:Function	
	public var onRoomVariablesUpdate:Function
	public var onRoundTripResponse:Function
	public var onUserCountChange:Function
	public var onUserEnterRoom:Function
	public var onUserLeaveRoom:Function
	public var onUserVariablesUpdate:Function
	public var onExtensionResponse:Function
	public var onSpectatorSwitched:Function
	public var onBuddyList:Function
	public var onBuddyListUpdate:Function
	public var onBuddyListError:Function
	public var onBuddyRoom:Function
	public var onRandomKey:Function
	
	//-----------------------------------------------------------------------------------//
	// Class constructor
	//-----------------------------------------------------------------------------------//
	function SmartFoxClient(objRef:Object)
	{
		super()
		
		// Object Reference:
		// optional param to keep a reference to a parent object
		this.objRef 		= objRef
		this.os 			= it.gotoandplay.smartfoxserver.ObjectSerializer.getInstance()
		this.isConnected 	= false
		this.debug 			= false
		
		// Initialize data
		initialize()
		
		// Array of tag names that should transformed in arrays by the messag2Object method
		this.arrayTags		= { uLs:true, rmList:true, vars:true, bList:true, vs:true }
	
		// Message Handlers
		this.messageHandlers = new Object();
		
		
		// Override default XMLSocket methods
		onConnect 	= connectionEstablished
		onData  	= gotData
		onXML   	= xmlReceived
		onClose 	= connectionClosed
		
		setupMessageHandlers()		
	}
	
	/**
	* Initialize properties and data structures
	*/
	private function initialize():Void
	{
		// RoomList
		this.roomList		= {}
		
		// BuddyList
		this.buddyList		= []
		this.buddyVars		= []
		
		// The currently active room
		this.activeRoomId	= null
		this.myUserId		= null
		this.myUserName		= ""
		this.playerId		= null
		
		this.changingRoom	= false
		this.amIModerator	= false
	}
	
	//-----------------------------------------------------------------------------------//
	// Get API version
	//-----------------------------------------------------------------------------------//
	public function getVersion():String
	{
		return this.majVersion + "." + this.minVersion + "." + this.subVersion
	}
	
	public function connected():Boolean
	{
		return this.isConnected
	}
	
	//-----------------------------------------------------------------------------------//
	// Setup the core message handlers
	//-----------------------------------------------------------------------------------//
	private function setupMessageHandlers()
	{
		addMessageHandler("sys", this.handleSysMessages)
		addMessageHandler("xt", this.handleExtensionMessages)
	}
	
	
	
	//-----------------------------------------------------------------------------------//
	// Add more MessageHanlders to the MessageHandler collection
	// All MessageHandlers object must implement a handleMessage() method
	//-----------------------------------------------------------------------------------//
	private function addMessageHandler(handlerId:String, handlerMethod:Function)
	{
		// Add the new handler only if it does not exist already
		if (this.messageHandlers[handlerId] == undefined)
		{
			this.messageHandlers[handlerId] = new Object()
			this.messageHandlers[handlerId].handleMessage = handlerMethod
		}
		else
		{
			trace("Warning: [" + handlerId + "] handler could not be created. A handler with this name already exist!")
		}
	
	}
	
	
	
	public function isModerator():Boolean
	{
		return this.amIModerator
	}
	
	
	
	//-----------------------------------------------------------------------------------//
	// System Messages Handler
	//-----------------------------------------------------------------------------------//
	private function handleSysMessages(xmlObj:Object, scope:Object)
	{
		// get "action" and "r" attributes
		var action:String		= xmlObj.attributes.action
		var fromRoom			= xmlObj.attributes.r

		
		// apiOK 
		if (action == "apiOK")
		{
			scope.isConnected = true
			scope.onConnection(true)
		}
		
		// apiKO => Bad API version
		else if (action == "apiKO")
		{
			scope.onConnection(false)
			trace("--------------------------------------------------------")
			trace(" WARNING! The API you are using are not compatible with ")
			trace(" the SmartFoxServer instance you're trying to connect to")
			trace("--------------------------------------------------------")
		}
		
		// logOK => login successfull
		else if (action == "logOK")
		{
			// store the uid that was assigned by the server
			scope.myUserId 	= xmlObj.login.attributes.id
			scope.myUserName = xmlObj.login.attributes.n
			scope.amIModerator = (xmlObj.login.attributes.mod == "0") ? false : true

			scope.onLogin({success:true, name:scope.myUserName, error:""})
	
			// autoget RoomList
			scope.getRoomList()
		}
		
		// logKO => login failed
		else if (action == "logKO")
		{
			var errorMsg = xmlObj.login.attributes.e
			scope.onLogin({success:false, name:"", error: errorMsg})
		}
		
		else if (action == "logout")
		{
			// Do the necessary cleanup
			scope.initialize()
			scope.onLogout()
			
		}
		
		// rmList => list of active rooms coming from server
		else if (action == "rmList")
		{
			var roomList = xmlObj.rmList.rmList
	
			// Pack data into a simpler format
			scope.roomList = new Array()
	
			for (var i in roomList)
			{
				// get ID for curr room
				var currRoomId = roomList[i].attributes.id
				
				// Grab Room Data
				var serverData = roomList[i].attributes
				
				var id 			= serverData.id
				var name 		= roomList[i].n.value
				var maxUsers 	= Number(serverData.maxu)
				var maxSpect	= Number(serverData.maxs)
				var isTemp 		= (serverData.temp) ? true : false
				var isGame 		= (serverData.game) ? true : false
				var isPrivate	= (serverData.priv) ? true : false
				var userCount	= Number(serverData.ucnt)
				var specCount	= Number(serverData.scnt)
				var isLimbo 	= (serverData.lmb) ? true : false
				
				scope.roomList[currRoomId] = new it.gotoandplay.smartfoxserver.Room(id, name, maxUsers, maxSpect, isTemp, isGame, isPrivate)
				scope.roomList[currRoomId].userCount = userCount
				scope.roomList[currRoomId].specCount = specCount
				
				// Set Limbo flag
				scope.roomList[currRoomId].setIsLimbo(isLimbo)
				
				// Point to the <vars></vars> node
				var roomVars = roomList[i].vars.vars
	
				// Generate Room Variables
				// Cycle through all variables in the XML
				// and recreate them in the room casting them to the right datatype
				for (var j = 0; j < roomVars.length; j++)
				{
					var vName = roomVars[j].attributes.n 
					var vType = roomVars[j].attributes.t
					var vVal  = roomVars[j].value
					
					// Dynamically cast the variable value to its original datatype
					var fn:Function
					
					if (vType == "b")
						fn = Boolean
					else if (vType == "n")
						fn = Number
					else if (vType == "s")
						fn = String
					else if (vType== "x")
						fn = function(x) { return null; }
					
					scope.roomList[currRoomId].variables[vName] = fn(vVal)
					
				}
			}
	
			// Fire event
			scope.onRoomListUpdate(scope.roomList)
		}
		
		// joinOK => room joined succesfully
		else if (action == "joinOK")
		{
			var roomId 		= xmlObj.uLs.attributes.r
			var userList 	= xmlObj.uLs.uLs
			var rVars		= xmlObj.vars.vars

			//
			// Set as the activeRoom the last joined room
			// -------------------------------------------
			// NOTE:
			// Since multiple room join is allowed the app. developer
			// has to specify the room in which the action takes place 
			// if it is different from the activeRoomId
			//
			scope.activeRoomId = Number(roomId)
	
			// get current Room and populates usrList
			var currRoom	= scope.roomList[roomId]
	
			currRoom.userList = new Object()
			
			// Get the playerId
			// -1 = no game room
			scope.playerId = xmlObj.pid.attributes.id
			
			// Also set the myPlayerId in the room
			// for multi-room applications
			currRoom.setMyPlayerIndex(xmlObj.pid.attributes.id)
			
			// Populate roomVariables
			currRoom.variables = new Object()
			
			for (var j = 0; j < rVars.length; j++)
			{
				var vName = rVars[j].attributes.n 
				var vType = rVars[j].attributes.t
				var vVal  = rVars[j].value
				
				// Dynamically cast the variable value to its original datatype
				var fn:Function
				
				if (vType == "b")
					fn = Boolean
				else if (vType == "n")
					fn = Number
				else if (vType == "s")
					fn = String
				else if (vType== "x")
					fn = function(x) { return null; }
				
				currRoom.variables[vName] = fn(vVal)
			}
			
			var uCount:Number = 0
			var	sCount:Number = 0
			
			// Populate Room userList
			for (var i = 0; i < userList.length; ++i)
			{
				// grab the user properties
				var name 	= userList[i].n.value
				var id   	= userList[i].attributes.i
				var isMod 	= userList[i].attributes.m
				var isSpec 	= userList[i].attributes.s
				var pid		= userList[i].attributes.p
				
				// set user Object (id, name ...)
				currRoom.userList[id] = new it.gotoandplay.smartfoxserver.User(id, name)
				currRoom.userList[id].isMod = (isMod == "1") ? true : false
				currRoom.userList[id].isSpec = (isSpec == "1") ? true : false
				currRoom.userList[id].pid = (pid == undefined) ? -1 : pid 
				
				if (currRoom.isGame() && isSpec == "1")
					sCount++
				else
					uCount++
				
				// Point to the <vars></vars> node
				var userVars = userList[i].vars.vars
				
				// Setup user variables Object
				currRoom.userList[id].variables = {}
	
				var item = currRoom.userList[id].variables
				
				// Cycle through all variables in the XML
				// and recreate them in the user casting them to the right datatype
				for (var j = 0; j < userVars.length; j++)
				{
					var vName = userVars[j].attributes.n 
					var vType = userVars[j].attributes.t
					var vVal  = userVars[j].value
					
					// Dynamically cast the variable value to its original datatype
					var fn:Function
					
					if (vType == "b")
						fn = Boolean
					else if (vType == "n")
						fn = Number
					else if (vType == "s")
						fn = String
					else if (vType== "x")
						fn = function(x) { return null; }
					
					item[vName] = fn(vVal)
				}
	
			}
			
			// Update room count
			currRoom.userCount = uCount
			currRoom.specCount = sCount
			
			// operation completed, release lock
			scope.changingRoom = false
	
			// Fire event!
			// Return a Room obj (with its id and name)
			scope.onJoinRoom(scope.roomList[roomId])
		}
		
		// joinKO => A problem was found when trying to join a room
		else if (action == "joinKO")
		{
			scope.changingRoom = false
			var error = xmlObj.error.attributes.msg
			scope.onJoinRoomError(error)
		}
		
		// userEntersRoom => a new user has joined the room
		else if (action == "uER")
		{
			// Get user param
			var usrId 	= xmlObj.u.attributes.i
			var usrName = xmlObj.u.n.value
			var isMod 	= xmlObj.u.attributes.m
			var isSpec 	= xmlObj.u.attributes.s
			var pid 	= xmlObj.u.attributes.p
			
			// get current Room and populates usrList
			var currRoom	= scope.roomList[fromRoom]
			
			// add new client
			// 
			// Note:
			// a shortcut would to do 
			// currRoom.usrList[uid] = xmlObj.user.attributes
			//
			// because attributes = {id, name}
			
			currRoom.userList[usrId] = new it.gotoandplay.smartfoxserver.User(usrId, usrName)
			currRoom.userList[usrId].isMod = (isMod == "1") ? true : false
			currRoom.userList[usrId].isSpec = (isSpec == "1") ? true : false
			currRoom.userList[usrId].pid = (pid == undefined) ? -1 : pid
			
			if (currRoom.isGame() && isSpec == "1")
			{
				currRoom.specCount++
			}
			else
				currRoom.userCount++
				
			
			// Point to the <vars></vars> node
			var userVars = xmlObj.u.vars.vars
			
			// Setup user variables Object
			currRoom.userList[usrId].variables = {}
	
			var item = currRoom.userList[usrId].variables
			
			// Cycle through all variables in the XML
			// and recreate them in the user casting them to the right datatype
			for (var j = 0; j < userVars.length; j++)
			{
				var vName = userVars[j].attributes.n 
				var vType = userVars[j].attributes.t
				var vVal  = userVars[j].value
				
				// Dynamically cast the variable value to its original datatype
				var fn:Function
					
				if (vType == "b")
					fn = Boolean
				else if (vType == "n")
					fn = Number
				else if (vType == "s")
					fn = String
				else if (vType== "x")
					fn = function(x) { return null; }
				
				item[vName] = fn(vVal)
			}
			
			scope.onUserEnterRoom(fromRoom, currRoom.userList[usrId])
		}
		
		// A user has left the room
		else if (action == "userGone")
		{
			//var roomId 	= xmlObj.user.attributes.r
			var usrId 		= xmlObj.user.attributes.id
			
			// get current Room
			var currRoom = scope.roomList[fromRoom]
			var usrName	= currRoom.userList[usrId].name
			var isSpec = currRoom.userList[usrId].isSpec
			
			delete currRoom.userList[usrId]
			
			if (currRoom.isGame() && isSpec)
			{
				currRoom.specCount--
			}
			else
				currRoom.userCount--
			
			// Send name and id to the application
			// because the user entry in the UserList has already been deleted
			
			scope.onUserLeaveRoom(fromRoom, usrId, usrName)
		}
		
		// You have a new public message
		else if (action == "pubMsg")
		{
			// sender id
			var usrId 	= xmlObj.user.attributes.id
			var textMsg	= xmlObj.txt.value
			
			textMsg		= scope.os.decodeEntities(textMsg.toString())
	
			// fire event 
			scope.onPublicMessage(textMsg.toString(), scope.roomList[fromRoom].userList[usrId], fromRoom)
		}
		
		// You have a new private message
		else if (action == "prvMsg")
		{
			// sender id
			var usrId 	= xmlObj.user.attributes.id
			var textMsg	= xmlObj.txt.value
	
			textMsg		= scope.os.decodeEntities(textMsg)
	
			// fire event 
			scope.onPrivateMessage(textMsg.toString(), scope.roomList[fromRoom].userList[usrId], usrId, fromRoom)
		}
		
		// You have a new Admin message
		else if (action == "dmnMsg")
		{
			// sender id
			var usrId 	= xmlObj.user.attributes.id
			var textMsg	= xmlObj.txt.value
	
			textMsg		= scope.os.decodeEntities(textMsg)
	
			// fire event 
			scope.onAdminMessage(textMsg.toString(), scope.roomList[fromRoom].userList[usrId])
		}
		
		// You have a new Admin message
		else if (action == "modMsg")
		{
			// sender id
			var usrId 	= xmlObj.user.attributes.id
			var textMsg	= xmlObj.txt.value
	
			textMsg		= scope.os.decodeEntities(textMsg)
	
			// fire event 
			scope.onModeratorMessage(textMsg.toString(), scope.roomList[fromRoom].userList[usrId])
		}
		
		// You have a new AS Object
		else if (action == "dataObj")
		{
			var senderId 	= xmlObj.user.attributes.id
			var obj		= xmlObj.dataObj.value
	
			var asObj	= scope.os.deserialize(obj)

			scope.onObjectReceived(asObj, scope.roomList[fromRoom].userList[senderId])			
		}
		
		// A user has changed his/her variables
		else if (action == "uVarsUpdate")
		{
			var usrId 	= xmlObj.user.attributes.id
			var variables 	= xmlObj.vars.vars
	
			var user = scope.roomList[fromRoom].userList[usrId]
			
			if (user.variables == undefined)
				user.variables = {}
				
			// A List of var names that changed in the last update
			var changedVars:Array = []
			
			for (var j = 0; j < variables.length; j++)
			{
				var vName = variables[j].attributes.n 
				var vType = variables[j].attributes.t
				var vVal  = variables[j].value
				
				// Add the vName to the list of changed vars
				// The changed List is an array that can contains all the
				// var names changed with numeric indexes but also contains
				// the var names as keys for faster search
				changedVars.push(vName)
				changedVars[vName] = true
				
				// Dynamically cast the variable value to its original datatype
				if (vType == "x")
				{
					delete user.variables[vName]
				}
				else
				{
					var fn:Function
					
					if (vType == "b")
						fn = Boolean
					else if (vType == "n")
						fn = Number
					else if (vType == "s")
						fn = String
						
					user.variables[vName] = fn(vVal)
				}
			}
			
			scope.onUserVariablesUpdate(user, changedVars)
		}
		
		// Notifies the roomVars update
		else if (action == "rVarsUpdate")
		{
			var variables 	= xmlObj.vars.vars
			
			var currRoom = scope.roomList[fromRoom]
			
			// A List of var names that changed in the last update
			var changedVars:Array = []
					
			if (currRoom.variables == undefined)
				currRoom.variables = new Object()
			
			for (var j = 0; j < variables.length; j++)
			{
				var vName = variables[j].attributes.n 
				var vType = variables[j].attributes.t
				var vVal  = variables[j].value
				
				// Add the vName to the list of changed vars
				// The changed List is an array that can contains all the
				// var names changed with numeric indexes but also contains
				// the var names as keys for faster search
				changedVars.push(vName)
				changedVars[vName] = true
				
				if (vType == "x")
				{
					delete currRoom.variables[vName]
				}
				else
				{
					// Dynamically cast the variable value to its original datatype
					var fn:Function
					
					if (vType == "b")
						fn = Boolean
					else if (vType == "n")
						fn = Number
					else if (vType == "s")
						fn = String
	
					currRoom.variables[vName] = fn(vVal)
				}
			}
			
			scope.onRoomVariablesUpdate(currRoom, changedVars)
		}
		
		// Room Create Request Failed
		else if (action == "createRmKO")
		{
			var errorMsg = xmlObj.room.attributes.e
			scope.onCreateRoomError(errorMsg)
		}
		
		// Receive and update about the user number in the other rooms
		else if (action == "uCount")
		{
			var uCount = xmlObj.attributes.u
			var sCount = xmlObj.attributes.s
			var room = scope.roomList[fromRoom]
			
			room.userCount = Number(uCount)
			room.specCount = Number(sCount)
			scope.onUserCountChange(room)
		}
		
		// A dynamic room was created
		else if (action == "roomAdd")
		{
			var xmlRoom 	= xmlObj.rm.attributes
			
			var rmId	= xmlRoom.id
			var rmName 	= xmlObj.rm.name.value
			var rmMax	= Number(xmlRoom.max)
			var rmSpec	= Number(xmlRoom.spec)
			var isTemp	= (xmlRoom.temp) ? true : false
			var isGame	= (xmlRoom.game) ? true : false
			var isPriv	= (xmlRoom.priv) ? true : false
			var isLimbo = (xmlRoom.limbo) ? true : false
			
			var newRoom 	= new it.gotoandplay.smartfoxserver.Room(rmId, rmName, rmMax, rmSpec, isTemp, isGame, isPriv)
			
			// set limbo
			newRoom.setIsLimbo(isLimbo)
				
			scope.roomList[rmId] = newRoom
			
			var variables 	= xmlObj.rm.vars.vars

			// A List of var names that changed in the last update
			newRoom.variables = new Object()
			
			for (var j = 0; j < variables.length; j++)
			{
				var vName = variables[j].attributes.n 
				var vType = variables[j].attributes.t
				var vVal  = variables[j].value
	
				// Dynamically cast the variable value to its original datatype
				var fn:Function
					
				if (vType == "b")
					fn = Boolean
				else if (vType == "n")
					fn = Number
				else if (vType == "s")
					fn = String
		
				newRoom.variables[vName] = fn(vVal)
	
			}
			
			scope.onRoomAdded(newRoom)
		}
		
		// A dynamic room was deleted
		else if (action == "roomDel")
		{
			var deletedId = xmlObj.rm.attributes.id
			
			var almostDeleted = scope.roomList[deletedId]
			
			delete scope.roomList[deletedId]
			
			scope.onRoomDeleted(almostDeleted)
			
		}
		
		// A room was left by the user
		// Used in multi-room mode
		else if (action == "leaveRoom")
		{
			var roomLeft = xmlObj.rm.attributes.id
			scope.onRoomLeft(roomLeft)
		}
		
		// RoundTrip response, for benchmark purposes only!
		else if (action == "roundTripRes")
		{
			scope.t2 = getTimer()
			scope.onRoundTripResponse(scope.t2 - scope.t1)
		}
		
		// Switch spectator response
		else if (action == "swSpec")
		{
			var playerId = Number (xmlObj.pid.attributes.id)
			var userId:Number = Number(xmlObj.pid.attributes.u)
			
			// Update room count values
			if (playerId > 0)
			{
				scope.roomList[fromRoom].userCount++
				scope.roomList[fromRoom].specCount--
			}
			
			// update is done behind the scenes, no event fired
			if (!isNaN(userId))
			{
				var currRoom = scope.roomList[fromRoom]
				currRoom.userList[userId].pid = playerId
				currRoom.userList[userId].isSpec = false
			}
			
			// this is the response to my request, let's fire an event
			else
			{
				scope.playerId = playerId
				scope.onSpectatorSwitched((scope.playerId > 0), scope.playerId, scope.roomList[fromRoom])
			}
		}
		
		// full buddyList update
		else if (action == "bList")
		{
			var bList = xmlObj.bList.bList
			
			if (bList == undefined)
			{
				scope.onBuddyListError(xmlObj.err.value)
				return
			}
			
			for (var i = 0; i < bList.length; i++)
			{
				var buddy = {}
				
				buddy.isOnline 	= (bList[i].attributes.s == "1") ? true : false
				buddy.name 	= bList[i].n.value
				buddy.id	= bList[i].attributes.i
				buddy.variables = {}
			
				var bVars = bList[i]["vs"].vs
				
				// Check buddy vars
				for (var j in bVars)
				{
					var vN:String = bVars[j].attributes.n
					var vV:String = bVars[j].value
					
					buddy.variables[vN] = vV
				}
				
				scope.buddyList.push(buddy)
			}
			
			scope.onBuddyList(scope.buddyList)
		}
		
		// buddyList update
		else if (action == "bUpd")
		{
			var b = xmlObj.b
			
			if (b == undefined)
			{
				scope.onBuddyListError(xmlObj.err.value)
				return
			}
			
			var buddy = {}
			buddy.name = b["n"].value
			buddy.id = b.attributes.i
			buddy.isOnline = (b.attributes.s == "1") ? true : false
			buddy.variables = {}
			
			var bVars = b["vs"].vs
			
			// Check buddy vars
			for (var i in bVars)
			{
				var vN:String = bVars[i].attributes.n
				var vV:String = bVars[i].value
				
				buddy.variables[vN] = vV
			}
			
			// Search for buddy item and overwrite it
			for (var i = 0; i < scope.buddyList.length; i++)
			{
				if (scope.buddyList[i].name == buddy.name)
				{
					scope.buddyList[i] = buddy
					break
				}
			}
			
			scope.onBuddyListUpdate(buddy)
		}
		
		// buddyList Add ::HIDDEN::
		else if (action == "bAdd")
		{
			var b = xmlObj.b
			
			var buddy = {}
			buddy.name = b.n.value
			buddy.id = b.attributes.i
			buddy.isOnline = (b.attributes.s == "1") ? true : false
			buddy.variables = {}
			
			var bVars = b["vs"].vs
			
			// Check buddy vars
			for (var i in bVars)
			{
				var vN:String = bVars[i].attributes.n
				var vV:String = bVars[i].value
				
				buddy.variables[vN] = vV
			}
			
			scope.buddyList.push(buddy)
			
			// Fire event
			scope.onBuddyList(scope.buddyList)
		}
		
		// buddyList update
		else if (action == "roomB")
		{
			var roomIds = xmlObj.br.attributes.r
			
			var ids = roomIds.toString().split(",")
			
			for (var i in ids)
				ids[i] = Number(ids[i])
				
			scope.onBuddyRoom(ids)
		}
		
		// handle the randomKey reception
		else if (action == "rndK")
		{
			var key:String = xmlObj.k.value
			scope.onRandomKey(key)
		}
	}
	
	
	
	//-----------------------------------------------------------------------------------//
	// Extension Messages Handler
	// 
	// TODO: by default if type is omitted then >>> type = "xml"
	//-----------------------------------------------------------------------------------//
	private function handleExtensionMessages(dataObj:Object, scope:Object, type:String)
	{
		// Handle and XML formatted object
		if (type == "xml")
		{
			// get "action" and "r" attributes
			var action   = dataObj.attributes.action
			var fromRoom = dataObj.attributes.r
			
			if (action == "xtRes")
			{
				//var senderId 		= dataObj.user.attributes.id
				//var obj			= dataObj.dataObj.value
				
				var obj				= dataObj.value
				var asObj:Object	= scope.os.deserialize(obj)

				scope.onExtensionResponse(asObj, type)	
			}
		}
		
		// Handle string formatted message
		else if (type == "str")
		{
			scope.onExtensionResponse(dataObj, type)
		}
		
		else if (type == "json")
		{
			scope.onExtensionResponse(dataObj.o, type)
		}
		
	}
	
	
	
	//-----------------------------------------------------------------------------------//
	// Send a message to a server extension
	//
	// xtName 	= unique name of the extension
	// cmdName 	= the command to execute
	// paramObj	= an object with the params for this command 
	// type		= can be "xml" or "str" in order to decide which protocol to use
	//		  TODO: xml should be default if type is omitted
	//
	// [roomId]	= (optional) the roomId, if using multirooms
	//-----------------------------------------------------------------------------------//
	public function sendXtMessage(xtName:String, cmdName:String, paramObj, type:String, roomId:Number)
	{
		if (roomId == undefined)
			roomId = this.activeRoomId
			
		// XML is default
		if (type == undefined)
			type = "xml"
			
		
		if (type == "xml")
		{
			var header:Object
			
			header 	= {t:"xt"}
			
			// Encapsulate message
			var xtReq:Object = {name: xtName, cmd: cmdName, param: paramObj}
			//var xmlmsg:String= "<dataObj><![CDATA[" + os.serialize(xtReq) + "]]></dataObj>"
			var xmlmsg:String= "<![CDATA[" + os.serialize(xtReq) + "]]>"
			
			this.send(header, "xtReq", roomId, xmlmsg)
		}
		
		else if (type == "str")
		{
			var hdr:String
			
			hdr = rawProtocolSeparator + "xt" + rawProtocolSeparator + xtName + rawProtocolSeparator + cmdName + rawProtocolSeparator + roomId + rawProtocolSeparator
			
			for (var i:Number = 0; i < paramObj.length; i++)
				hdr += paramObj[i].toString() + rawProtocolSeparator

			this.sendString(hdr)
		}
		
		else if (type == "json")
		{
			var body:Object = {}
			body.x = xtName
			body.c = cmdName
			body.r = roomId
			body.p = paramObj
			
			var obj:Object = {}
			obj.t = "xt"
			obj.b = body
			
			try 
			{
				var msg:String = it.gotoandplay.smartfoxserver.JSON.stringify(obj)
				this.sendJson(msg)
			} 
			catch(ex) 
			{
				if (this.debug)
				{
					trace("Error in sending JSON message.")
					trace(ex.name + " : " + ex.message + " : " + ex.at + " : " + ex.text)
				}
			}
		}
	}
	
	
	
	//-----------------------------------------------------------------------------------
	// Debug ONLY
	//-----------------------------------------------------------------------------------
	public function dumpObj(obj:Object, depth:Number)
	{
		if (depth == undefined)
			depth = 0

		if (this.debug)
		{
			if (depth == 0)
			{
				trace("+-----------------------------------------------+")
				trace("+ Object Dump                                   +")
				trace("+-----------------------------------------------+")
			}
			
			for (var key in obj)
			{
				var item = obj[key]
				var typ = typeof(item)
				
				if (typ != "object")
				{
					var msg = ""
					for (var i = 0; i < depth; i++)
						msg += "\t"
					
					msg += key + " : " + item + " ( " + typ + " )"
					trace(msg)
				}
				else
					dumpObj(item, depth + 1)
			}
			
		}
	}
	
	
	
	//-----------------------------------------------------------------------------------
	// Login Request
	//-----------------------------------------------------------------------------------
	public function login(zone:String, nick:String, pass:String)
	{
		var header 	= {t:"sys"}
		var message 	= "<login z='" + zone + "'><nick><![CDATA[" + nick + "]]></nick><pword><![CDATA[" + pass + "]]></pword></login>"

		this.send(header, "login", 0, message)
	}
	
	
	public function logout()
	{
		var header 	= {t:"sys"}
		this.send(header, "logout", -1, "")
	}
	
	
	
	//-----------------------------------------------------------------------------------
	// Request Room List
	//-----------------------------------------------------------------------------------
	public function getRoomList()
	{
		var header 	= {t:"sys"}
		this.send(header, "getRmList", (this.activeRoomId ? this.activeRoomId : -1), "")
	}
	
	
	
	//-----------------------------------------------------------------------------------
	// Request autoJoin in defaultRoom
	//-----------------------------------------------------------------------------------
	public function autoJoin()
	{
		var header 	= {t:"sys"}
		this.send(header, "autoJoin", (this.activeRoomId ? this.activeRoomId : -1) , "")
	}
	
	
	
	//-----------------------------------------------------------------------------------
	// Join a new room:
	// 
	// roomId 		= id of the new room to join
	// pword		= (OPTIONAL) password (if any) for room
	// isSpectator		= (OPTIONAL) log as a spectator in a game room
	// dontLeave		= (OPTIONAL) leave the current room ? (true/false). Allow multiple room presence
	// oldRoom		= (OPTIONAL) the id of a room to disconnect before entering the new one
	// 
	// NOTE:
	// the server always disconnect the ActiveRoom before enetering a new one
	// if you don't want to leave the ActiveRoom, set the leaveCurrRoom = false
	// Multiple rooms can be used for special sub-room group chat etc...
	//
	// UPDATE:
	// the newRoom param accepts both a Number ( the room Id ) or a String ( the room name, case sensitive )
	//-----------------------------------------------------------------------------------
	public function joinRoom(newRoom, pword:String, isSpectator:Boolean, dontLeave:Boolean, oldRoom:Number)
	{
		var newRoomId = null
		var isSpec:Number
		
		if (isSpectator)
			isSpec = 1
		else
			isSpec = 0
		
		if (!this.changingRoom)
		{
			if (typeof newRoom == "number")
			{
				newRoomId = newRoom
			}
			else
			{
				// Search the room
				for (var i in this.roomList)
				{
					//trace("scanning " + this.roomList[i].getName())
					if (this.roomList[i].name == newRoom)
					{
						newRoomId = this.roomList[i].id
						break
					}
				}
			}
			
			if (newRoomId != null)
			{
				var header:Object = {t:"sys"} 

				var leaveCurrRoom:String = (dontLeave) ? "0": "1"
				
				// Send oldroom id, even if you don't want to disconnect
				var roomToLeave:Number
				
				if (oldRoom)
					roomToLeave = oldRoom			
				else
					roomToLeave = this.activeRoomId
			
				// CHECK:
				// if this.activeRoomId is null no room has already been entered
				if (this.activeRoomId == null)
				{
					leaveCurrRoom = "0"
					roomToLeave = -1
				}
				
				var message:String = "<room id='" + newRoomId + "' pwd='" + pword + "' spec='" + isSpec + "' leave='" + leaveCurrRoom + "' old='" + roomToLeave + "' />"
				
				this.send(header, "joinRoom", ((this.activeRoomId) ? this.activeRoomId:-1), message)
				this.changingRoom = true
			}
			else
			{
				trace("SmartFoxError: requested room to join does not exist!")
			}
		}
	}
	
	
	
	
	//-----------------------------------------------------------------------------------//
	// Send a [PUBLIC] text message to the users
	// msg 	= the txt
	// roomId	= (OPTIONAL) the id of the room, if working with multirooms
	//-----------------------------------------------------------------------------------//
	public function sendPublicMessage(msg:String, roomId:Number)
	{
		if (roomId == undefined)
			roomId = this.activeRoomId
			
		var header:Object = {t:"sys"}
		
		// Encapsulate message
		var xmlmsg:String = "<txt><![CDATA[" + os.encodeEntities(msg) + "]]></txt>"
	
		this.send(header, "pubMsg", roomId, xmlmsg)
		
	}
	
	
	
	//-----------------------------------------------------------------------------------//
	// Send a [PRIVATE] text message to one user
	// msg 	= the txt
	// userId	= the id of the recipient user
	// roomId	= (OPTIONAL) the id of the room, if working with multirooms
	//-----------------------------------------------------------------------------------//
	public function sendPrivateMessage(msg:String, userId:Number, roomId:Number)
	{
		if (roomId == undefined)
			roomId = this.activeRoomId
			
		var header:Object = {t:"sys"}
		
		// Encapsulate message
		var xmlmsg:String = "<txt rcp='" + userId + "'><![CDATA[" + os.encodeEntities(msg) + "]]></txt>"
	
		this.send(header, "prvMsg", roomId, xmlmsg)
		
	}
	
	/**
	 * Send moderator message
	 * 
	 * @usage   
	 * @param   msg  	the message
	 * @param   type 	the  type of message (to User, to Room, to Zone)
	 * @param   id   	id of user or room
	 * 
	 * @return  nothing
	 */
	public function sendModeratorMessage(msg:String, type:String, id:Number)
	{
		var header:Object = {t:"sys"}
		
		// Encapsulate message
		var xmlmsg:String = "<txt t='" + type + "' id='" + id + "'><![CDATA[" + os.encodeEntities(msg) + "]]></txt>"
	
		this.send(header, "modMsg", this.activeRoomId, xmlmsg)
	}
	
	
	//-----------------------------------------------------------------------------------//
	// Serialize Actionscript Object and send it
	// Requires ObjectSerializerClass
	//-----------------------------------------------------------------------------------//
	public function sendObject(obj:Object, roomId:Number)
	{
		// If roomId is passed then use it
		// otherwise just use the current active room id
		if (roomId == undefined)
			roomId = this.activeRoomId
	
		var xmlPacket:String = "<![CDATA[" + os.serialize(obj) + "]]>"
		var header:Object = {t:"sys"}
	
		this.send(header, "asObj", roomId, xmlPacket)
	}
	
	//-----------------------------------------------------------------------------------//
	// Serialize Actionscript Object and send it to a list of recipients
	//-----------------------------------------------------------------------------------//
	public function sendObjectToGroup(obj:Object, userList:Array, roomId:Number)
	{
		if (roomId == undefined)
			roomId = this.activeRoomId
		
		var _$$_:String = ""
		
		for (var i in userList)
		{
			if (!isNaN(userList[i]))
				_$$_ += userList[i] + ","
		}
		_$$_ = _$$_.substr(0, _$$_.length - 1)
		
		obj._$$_ = _$$_
		
		var xmlPacket:String = "<![CDATA[" + os.serialize(obj) + "]]>"
		var header:Object = {t:"sys"}
		
		this.send(header, "asObjG", roomId, xmlPacket)
	}
	
	//
	// Create / Update user variables on server
	// the varObj is an Objects of variables
	//
	public function setUserVariables(varObj:Object, roomId:Number)
	{
		if (roomId == undefined)
			roomId = this.activeRoomId
			
		var header:Object = {t:"sys"}
		
		// Encapsulate Variables
		var xmlMsg:String = "<vars>"
		
		// Reference to the user setting the variables
		var user:Object = this.roomList[roomId].userList[this.myUserId]
		
		for (var vName in varObj)
		{
			var vValue = varObj[vName]
			var t = null
			
			// Check type
			if (typeof vValue == "boolean")
			{
				t = "b"
				vValue = (vValue) ? 1:0			// transform in number before packing in xml
			}
			else if (typeof vValue == "number")
				t = "n"
			else if (typeof vValue == "string")
				t = "s"
			else if (typeof vValue == "null")
			{
				t = "x"
				delete user.variables[vName]
			}
			
			if (t != null)
			{
				user.variables[vName] = vValue
				xmlMsg += "<var n='" + vName + "' t='" + t + "'><![CDATA[" + vValue + "]]></var>"
			}
		}
		
		xmlMsg += "</vars>"
	
		this.send(header, "setUvars", roomId, xmlMsg)
	}
	
	//
	// Create / Update Buddy Variables on server
	// the varObj is an Objects of variables
	//
	public function setBuddyVariables(varObj:Object)
	{			
		var header:Object = {t:"sys"}
		
		// Encapsulate Variables
		var xmlMsg:String = "<vars>"
		
		// Reference to the user setting the variables
		
		for (var vName:String in varObj)
		{
			var vValue:String = varObj[vName]
			
			// if variable is new or updated send it and update locally
			if (this.buddyVars[vName] != vValue)
			{
				this.buddyVars[vName] = vValue
				xmlMsg += "<var n='" + vName + "'><![CDATA[" + vValue + "]]></var>"
			}
		}
		
		xmlMsg += "</vars>"
	
		this.send(header, "setBvars", -1, xmlMsg)
	}
	
	
	//-----------------------------------------------------------------------------------
	//  D E B U G   O N L Y - Dumps the RoomList structure
	//-----------------------------------------------------------------------------------
	private function dumpRoomList()
	{
		for (var j in this.roomList)
		{
			var room = this.roomList[j]
			
			trace(newline)
			trace("-------------------------------------")
			trace(" > Room: (" + j + ") - " + room.getName())
			trace("isTemp: " + room.isTemp())
			trace("isGame: " + room.isGame())
			trace("isPriv: " + room.isPrivate())
			trace("Users: " + room.getUserCount() + " / " + room.getMaxUsers())
			trace("Variables: ")
			
			for (var i in room.variables)
			{
				trace("\t" + i + " = " + room.getVariable(i))
			}
			
			trace(newline + "UserList: ")
			
			var uList = room.getUserList()
			
			for (var i in uList)
			{
				trace("\t" + uList[i].getId() + " > " + uList[i].getName())
			}
		}
	}
	
	
	
	//-----------------------------------------------------------------------------------//
	// Request a new room creation to the server
	// the roomObj can have these properties:
	//
	// name 	= room name
	// password 	= room password
	// description 	= a brief room description (optional) || NON IMPLEMENTED FOR NOW ||
	// maxUsers 	= max number of users
	// maxSpectators= max number of spectators for game room
	// updatable 	= boolean to check if room is updatable
	// variables 	= an object filled with vars
	//
	// --- Private memebers ---------------------------
	// isTemp 	= all room created are runtime should be temporary 
	// isGame 	= mark the room as a game room
	//-----------------------------------------------------------------------------------//
	public function createRoom(roomObj:Object, rId:Number)
	{
		var roomId:Number	= (rId == undefined) ? this.activeRoomId : rId
		var header:Object 	= {t:"sys"}
			
		var updatable:Number 	= (roomObj.updatable) ? 1 : 0
		var isGame:Number 	= (roomObj.isGame) ? 1 : 0
		var exitCurrent:Number	= 1
		var maxSpectators:Number= roomObj.maxSpectators
		
		// If this is a Game Room you will leave the current room
		// and log into the new game room
		// If you specify exitCurrentRoom = false you will not be logged out of the curr room.
		if (isGame && roomObj.exitCurrentRoom != undefined)
		{
			exitCurrent	= (roomObj.exitCurrentRoom) ? 1:0
		}
		
		var xmlMsg:String  = "<room upd='" + updatable + "' tmp='1' gam='" + isGame + "' spec='" + maxSpectators + "' exit='" + exitCurrent + "'>"
		
		xmlMsg += "<name><![CDATA[" + roomObj.name + "]]></name>"
		xmlMsg += "<pwd><![CDATA[" + roomObj.password + "]]></pwd>"
		xmlMsg += "<max>" + roomObj.maxUsers + "</max>"
		//xmlMsg += "<desc><![CDATA[" + roomObj.description + "]]></desc>"
		
		if (roomObj.uCount != undefined)
		{
			xmlMsg += "<uCnt>" + (roomObj.uCount ? "1" : "0") + "</uCnt>"
		}
		
		// Set extension for room
		if (roomObj.extension != undefined)
		{
			xmlMsg += "<xt n='" + roomObj.extension.name
			xmlMsg += "' s='" + roomObj.extension.script + "' />"
		}
		
		// Set Room Variables on creation
		if (roomObj.vars == undefined)
			xmlMsg += "<vars></vars>"
		else
		{
			xmlMsg += "<vars>"
			
			for (var i in roomObj.vars)
			{
				xmlMsg += getXmlRoomVariable(roomObj.vars[i])
			}
			
			xmlMsg += "</vars>"
		}
		
		xmlMsg += "</room>"
			
		this.send(header, "createRoom", roomId, xmlMsg)
	}
	
	
	
	//-----------------------------------------------------------------------------------
	//  Leave a room
	//  Can be used when a client is connected in more than one room at a time
	//  If the user is connected in one room only this command will have no effect
	//-----------------------------------------------------------------------------------
	public function leaveRoom(roomId)
	{
		var header:Object = {t:"sys"}
		var xmlMsg:String = "<rm id='" + roomId + "' />"
		
		this.send(header, "leaveRoom", roomId, xmlMsg)
	}
	
	
	//-----------------------------------------------------------------------------------
	//  Search for a room
	//  you can pass as the roomId, both its numeric Id or its name
	//-----------------------------------------------------------------------------------
	public function getRoom(roomId)
	{
		if (typeof roomId == "number")
		{
			return this.roomList[roomId]
		}
		else if (typeof roomId == "string")
		{
			for (var i in this.roomList)
			{
				var r = this.roomList[i]
	
				if (r.getName() == roomId)
				{
					return r;
				}
			}
		}
	}
	
	
	
	//-----------------------------------------------------------------------------------
	// Returns the currently active Room object
	//
	// NOTE: You can use this only if you're not using
	// the multiRoom feature.
	//-----------------------------------------------------------------------------------
	public function getActiveRoom():it.gotoandplay.smartfoxserver.Room
	{
		return this.roomList[this.activeRoomId]
	}
	
	
	
	public function setRoomVariables(varObj:Array, roomId:Number, setOwnership:Boolean)
	{
		if (roomId == undefined)
			roomId = this.activeRoomId
		
		if (setOwnership == undefined)
			setOwnership = true
			
		var header:Object 	= {t:"sys"}
		
		// Encapsulate Variables
		// so (setOwnership) attribute is sent only if specified as false
		var xmlMsg:String 
		if (setOwnership)
			xmlMsg = "<vars>"
		else
			xmlMsg = "<vars so='0'>"	
		
		for (var i:Number = 0; i < varObj.length; i++)
			xmlMsg += getXmlRoomVariable(varObj[i])
		
		xmlMsg += "</vars>"
	
		this.send(header, "setRvars", roomId, xmlMsg)
	}
	
	
	
	//-----------------------------------------------------------------------------------
	// Returns the XML representation of a RoomVariable
	// 
	// used by CreateRoom() and setRoomVariables()
	//-----------------------------------------------------------------------------------
	private function getXmlRoomVariable(rVar):String
	{
		// Get properties for this var
		var vName	= rVar.name
		var vValue 	= rVar.val
		var vPrivate	= (rVar.priv) ? "1":"0"
		var vPersistent = (rVar.persistent) ? "1":"0"
		
		var t = null
		
		// Check type
		if (typeof vValue == "boolean")
		{
			t = "b"
			vValue = (vValue) ? 1:0			// transform in number before packing in xml
		}
		else if (typeof vValue == "number")
			t = "n"
		else if (typeof vValue == "string")
			t = "s"
		else if (typeof vValue == "null")
			t = "x"
		
		if (t != null)
			return "<var n='" + vName + "' t='" + t + "' pr='" + vPrivate + "' pe='" + vPersistent + "'><![CDATA[" + vValue + "]]></var>"
		else
			return ""
	}
	
	
	
	//-----------------------------------------------------------------------------------
	// Load the buddyList
	//-----------------------------------------------------------------------------------
	public function loadBuddyList()
	{
		var header:Object = {t:"sys"}
		this.send(header, "loadB", -1, "")
	}
	
	
	//-----------------------------------------------------------------------------------
	// Add a buddy to the buddyList
	//-----------------------------------------------------------------------------------
	public function addBuddy(buddyName:String)
	{
		if (buddyName != this.myUserName && !this.checkBuddy(buddyName))
		{
			
			// Look for userId
			var id = this.roomList[this.activeRoomId].getUserList().getUser(buddyName)
				
			// Send buddy to server
			var header:Object = {t:"sys"}
			var xmlMsg:String = "<n>" + buddyName + "</n>"
			
			this.send(header, "addB", -1, xmlMsg)
		}
	}
	
	
	
	//-----------------------------------------------------------------------------------
	// Removes a buddy from the buddyList
	//-----------------------------------------------------------------------------------
	public function removeBuddy(buddyName:String)
	{
		//var buddy:Object

		for (var i in this.buddyList)
		{
			if (this.buddyList[i].name == buddyName)
			{
				delete this.buddyList[i]
				break
			}
		}
		
		var header:Object = {t:"sys"}
		var xmlMsg:String = "<n>" + buddyName + "</n>"
			
		// Send 
		this.send(header, "remB", -1, xmlMsg)
			
		this.onBuddyList(this.buddyList)
	}
	
	//-----------------------------------------------------------------------------------
	// Get the current room/rooms for this buddy
	//-----------------------------------------------------------------------------------
	public function getBuddyRoom(buddy)
	{
		// If buddy is active...
		if (buddy.id != -1)
			this.send({t:"sys", bid:buddy.id}, "roomB", -1, "<b id='" + buddy.id + "' />")
	}
	
	//-----------------------------------------------------------------------------------
	// Checks if a buddy already exist
	//-----------------------------------------------------------------------------------
	public function checkBuddy(name):Boolean
	{
		var res:Boolean = false
		
		for (var i in this.buddyList)
		{
			if (this.buddyList[i].name == name)
			{
				res = true
				break
			}
		}
		
		return res
	}
	
	
	//-----------------------------------------------------------------------------------
	// Clear buddyList
	//-----------------------------------------------------------------------------------
	public function clearBuddyList()
	{
		this.buddyList = []
		
		this.send({t:"sys"}, "clearB", -1, "")
		
		this.onBuddyList(this.buddyList)
	}
	
	
	public function roundTripBench()
	{
		this.t1 		= getTimer()
		
		var header:Object	= {t:"sys"}
		this.send(header, "roundTrip", this.activeRoomId, "")
	}
	
	
	// Turn a spectator into a player
	public function switchSpectator(roomId:Number)
	{
		if (roomId == undefined)
			roomId = this.activeRoomId
		
		var header:Object	= {t:"sys"}
		this.send(header, "swSpec", roomId, "")
	}
	
	
	
	// Get a random key from server
	public function getRandomKey()
	{
		this.send({t:"sys"}, "rndK", -1, "")
	}
	
	
	private function send(header:Object, action:String, fromRoom:Number, message:String)
	{
		// Setup Msg Header
		var xmlMsg:String = this.makeHeader(header);
		
		// Setup Body
		xmlMsg += "<body action='" + action + "' r='" + fromRoom + "'>" + message + "</body>" + this.closeHeader()
	
		if (this.debug)
			trace("[Sending]: " + xmlMsg + newline)
	
		super.send(xmlMsg)
	}
	
	
	public function uploadFile(fileRef, id:Number, nick:String, port:Number):Void
	{
		if (id == undefined)
			id = this.myUserId
		
		if (nick == undefined)
			nick = this.myUserName
			
		if (port == undefined)
			port = this.httpPort
		
		fileRef.upload("http://" + this.ipAddress + ":" + port + "/default/Upload.py?id=" + id + "&nick=" + nick)
		
		if (this.debug)
			trace("[UPLOAD]: http://" + this.ipAddress + ":" + port + "/default/Upload.py?id=" + id + "&nick=" + nick)
	}
	
	public function getUploadPath():String
	{
		return "http://" + this.ipAddress + ":" + this.httpPort + "/default/uploads/"
	}
	
	//-----------------------------------------------------------------------------------
	// sendString sends a string formatted message instead of an XML one
	// The string is separated by a separator character
	// The first two fields are mandatory:
	//
	// % handlerId % actionName % param % param % ... % ... %
	//-----------------------------------------------------------------------------------
	private function sendString(message:String)
	{
		if (this.debug)
			trace("[Sending]: " + message + newline)
				
		super.send(message)
	}
	
	private function sendJson(message:String)
	{
		if (this.debug)
			trace("[Sending - json]: " + message + newline)
				
		super.send(message)
	}
	
	
	// Override parent class method
	private function gotData(message:String) 
	{
		if (message.charAt(0) == rawProtocolSeparator)
			strReceived(message)

		else if (message.charAt(0) == "<")
			onXML(new XML(message));
			
		else if (message.charAt(0) == "{")
			jsonReceived(message)
	}
	
	
	
	public function connectionEstablished(ok:Boolean)
	{
		if (ok)
		{
			var header:Object = {t:"sys"}
			var xmlMsg:String = "<ver v='" + this.majVersion.toString() + this.minVersion.toString() + this.subVersion.toString() + "' />"	
			this.send(header, "verChk", 0, xmlMsg)
		}
		else
			this.onConnection(false)
	}
	
	
	private function connectionClosed()
	{
		// Fire client event
		this.isConnected = false
		onConnectionLost()
	}
	
	
	
	public function connect(serverIp:String, serverPort:Number)
	{
		if (!isConnected)
		{
			this.ipAddress = serverIp
			this.portNumber = serverPort
			super.connect(serverIp, serverPort)
		}
		else
		{
			trace("WARNING! You're already connected to -> " + this.ipAddress + ":" + this.portNumber)
		}
	}
	
	
	
	public function disconnect()
	{
		close()
		isConnected = false
		
		onConnectionLost()
	}
	
	
	
	private function xmlReceived(message:XML)
	{
		var xmlObj:Object = new Object();
	
		message2Object(message.childNodes, xmlObj)
	
		if (this.debug)
			trace("[Received]: " + message)
	
		// get Handler
		var id:String = xmlObj.msg.attributes.t
	
		messageHandlers[id].handleMessage(xmlObj.msg.body, this, "xml")
	}
	
	
	
	
	//-----------------------------------------------------------------------------------
	// Handle string message from server
	//-----------------------------------------------------------------------------------
	private function strReceived(message:String)
	{
		var params:Array = message.substr(1, message.length - 2).split(rawProtocolSeparator)
	
		if (this.debug)
			trace("[Received - Str]: " + message)
		
		// get Handler
		var id:String = params[0]

		// the last parameter specify that we have a string formatted message
		messageHandlers[id].handleMessage(params.splice(1, params.length -1), this, "str")
	}
	
	private function jsonReceived(message:String)
	{
		var jso = it.gotoandplay.smartfoxserver.JSON.parse(message)
		
		if (this.debug)
			trace("[Received - json]: " + message)
			
		var id:String = jso["t"]
		messageHandlers[id].handleMessage(jso["b"], this, "json")
		
	}
	
	
	//-------------------------------------------------------
	// Message Parser :
	// parses the xml message into an Actionscript Object
	//
	// Retrieve attributes = xmlObj.node.attributs.attrName
	// Retrieve tag value  = xmlObj.node.value
	//-------------------------------------------------------
	private function message2Object(xmlNodes, parentObj)
	{
		// counter
		var i = 0
		var currObj = null
	
		while(i < xmlNodes.length)
		{
			// get first child inside XML object
			var node	= xmlNodes[i]
			var nodeName	= node.nodeName
			var nodeValue	= node.nodeValue
	
			// Check if parent object is an Array or an Object
			if (parentObj instanceof Array)
			{
				currObj = {}
				parentObj.push(currObj)
				currObj = parentObj[parentObj.length - 1]
	
			}
			else
			{
				parentObj[nodeName] = new Object()
				currObj = parentObj[nodeName]
			}
	
			//-------------------------------------------
			// Save attributes
			//-------------------------------------------
			for (var att in node.attributes)
			{
				if (typeof currObj.attributes == "undefined")
					currObj.attributes = {}
	
				var attVal = node.attributes[att]
	
				// Check if it's number
				if (!isNaN(Number(attVal)))
					attVal = Number(attVal)
	
				// Check if it's a boolean
				if (attVal.toLowerCase() == "true")
					attVal = true
			
				else if (attVal.toLowerCase() == "false")
					attVal = false
	
				// Store the attribute
				currObj.attributes[att] = attVal
			}
	
			// If this node is present in the arrayTag Object
			// then a new Array() is created to hold its memebers
			if (this.arrayTags[nodeName])
			{
				currObj[nodeName] = []
				currObj = currObj[nodeName]
			}
	
			// Check if we have more subnodes
			if (node.hasChildNodes() && node.firstChild.nodeValue == undefined)
			{
				// Call this function recursively until node has no more children
				var subNodes = node.childNodes
				message2Object(subNodes, currObj)
			}
			else
			{
				nodeValue = node.firstChild.nodeValue

				if (!isNaN(nodeValue) && node.nodeName != "txt")
					nodeValue = Number(nodeValue)
	
				currObj.value = nodeValue
			}
	
			i++
		}
	
	}
	
	
	
	private function makeHeader(headerObj:Object):String
	{
		var xmlData:String = "<msg"
	
		for (var item in headerObj)
		{
			xmlData += " " + item + "='" + headerObj[item] + "'"
		}
	
		xmlData += ">"
	
		return xmlData
	}
	
	
	
	private function closeHeader():String
	{
		return "</msg>"
	}
}





