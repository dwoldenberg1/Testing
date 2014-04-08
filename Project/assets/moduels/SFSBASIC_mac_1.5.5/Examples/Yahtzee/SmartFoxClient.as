/**
	SmartFoxClient API
	Actionscript 1.0 Client API

	ver 1.3.0 -- September 5th, 2006

	(c) gotoAndPlay --- www.gotoandplay.it

*/



//-----------------------------------------------------------------------------------//
// Class constructor
//-----------------------------------------------------------------------------------//
SmartFoxClient = function(objRef)
{
	// Object Reference:
	// optional param to keep a reference to a parent object
	this.objRef 		= objRef

	// Versioning stuff
	this.majVersion = 1
	this.minVersion = 3
	this.subVersion = 0

	// Server XMLSocket
	this.server 		= new XMLSocket()

	// RoomList Object
	this.roomList		= new Object()
	
	// BuddyList Object
	this.buddyList		= new Array()
	this.buddyVars		= new Array()
	
	// The currently active room
	this.activeRoomId	= null
	this.myUserId		= null
	this.myUserName		= ""
	this.amIModerator	= false
	this.playerId		= null
	this.debug 		= true
	
	this.isConnected 	= false
	this.changingRoom	= false
	
	// Array of tag names that should transformed in arrays by the messag2Object method
	this.arrayTags		= { userList:true, rmList:true, vars:true, bList:true, vs:true }

	// Message Handlers
	this.messageHandlers = new Object();

	this.setupMessageHandlers()
}


XMLSocket.prototype.onData = function (message) 
{
	if (message.charAt(0) == "%")
	{		 
		this.strReceived(message)
	}
	else if (message.charAt(0) == "<")
		this.onXML(new XML(message));
}



//-----------------------------------------------------------------------------------//
// Get API Version
//-----------------------------------------------------------------------------------//
SmartFoxClient.prototype.getVersion = function()
{
	return this.majVersion + "." + this.minVersion + "." + this.subVersion
}


//-----------------------------------------------------------------------------------//
// Get the moderator flag
//-----------------------------------------------------------------------------------//
SmartFoxClient.prototype.isModerator = function()
{
	return this.amIModerator
}

//-----------------------------------------------------------------------------------//
// Setup the core message handlers
//-----------------------------------------------------------------------------------//
SmartFoxClient.prototype.setupMessageHandlers = function()
{
	this.addMessageHandler("sys", this.handleSysMessages)
	this.addMessageHandler("xt", this.handleExtensionMessages)

}



//-----------------------------------------------------------------------------------//
// Add more MessageHanlders to the MessageHandler collection
// All MessageHandlers object must implement a handleMessage() method
//-----------------------------------------------------------------------------------//
SmartFoxClient.prototype.addMessageHandler = function (handlerId, handlerMethod)
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



//-----------------------------------------------------------------------------------//
// System Messages Handler
//-----------------------------------------------------------------------------------//
SmartFoxClient.prototype.handleSysMessages = function(xmlObj, parent)
{
	// get "action" and "r" attributes
	var action 		= xmlObj.attributes.action
	var fromRoom 		= xmlObj.attributes.r
	
	
	if (action == "apiOK")
	{
		parent.onConnection(true)
	}
	else if (action == "apiKO")
	{
		parent.onConnection(false)
		trace("--------------------------------------------------------")
		trace(" WARNING! The API you are using are not compatible with ")
		trace(" the SmartFoxServer instance you're trying to connect to")
		trace("--------------------------------------------------------")
	}
	
	
	// logOK => login successfull
	else if (action == "logOK")
	{		
		// store the uid that was assigned by the server
		parent.myUserId 	= xmlObj.login.attributes.id
		parent.myUserName 	= xmlObj.login.attributes.n
		parent.amIModerator 	= (xmlObj.login.attributes.mod == "0") ? false : true
		
		parent.onLogin({success:true, name:parent.myUserName, error:""})

		// autoget RoomList
		parent.getRoomList()
	}
	
	// logKO => login failed
	else if (action == "logKO")
	{
		var errorMsg = xmlObj.login.attributes.e
		parent.onLogin({success:false, name:"", error: errorMsg})
	}
	
	// rmList => list of active rooms coming from server
	else if (action == "rmList")
	{
		var roomList = xmlObj.rmList.rmList

		// Pack data into a simpler format
		parent.roomList = new Array()

		for (var i in roomList)
		{

			// get ID for curr room
			var currRoomId = roomList[i].attributes.id
			
			// Grab Room Data
			var serverData = roomList[i].attributes
			
			var id 		= serverData.id
			var name 	= roomList[i].n.value
			var maxUsers 	= Number(serverData.maxu)
			var maxSpect	= Number(serverData.maxs)
			var isTemp 	= (serverData.temp) ? true : false
			var isGame 	= (serverData.game) ? true : false
			var isPrivate	= (serverData.priv) ? true : false
			var userCount	= Number(serverData.ucnt)
			var specCount	= Number(serverData.scnt)
			var isLimbo 	= (serverData.lmb) ? true : false

			parent.roomList[currRoomId] = new _ServerRoom(id, name, maxUsers, maxSpect, isTemp, isGame, isPrivate)
			parent.roomList[currRoomId].userCount = userCount
			parent.roomList[currRoomId].specCount = specCount
			
			// Set Limbo flag
			parent.roomList[currRoomId].setIsLimbo(isLimbo)
			
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
				if (vType == "b")
					var fn = Boolean
				else if (vType == "n")
					var fn = Number
				else if (vType == "s")
					var fn = String
				else if (vType== "x")
					var fn = function(n) { return null; }
				
				parent.roomList[currRoomId].variables[vName] = fn(vVal)
				
			}
		}

		// Fire event
		parent.onRoomListUpdate(parent.roomList)
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
		parent.activeRoomId = Number(roomId)

		// get current Room and populates usrList
		var currRoom	= parent.roomList[roomId]

		currRoom.userList = new Object()
		
		// Get the playerId
		// -1 = no game room
		parent.playerId = xmlObj.pid.attributes.id
		
		// Also set the myPlayerId in the room
		// for multi-room applications
		currRoom.setMyPlayerId(xmlObj.pid.attributes.id)
		
		// Populate roomVariables
		currRoom.variables = new Object()
		
		for (var j = 0; j < rVars.length; j++)
		{
			var vName = rVars[j].attributes.n 
			var vType = rVars[j].attributes.t
			var vVal  = rVars[j].value
			
			// Dynamically cast the variable value to its original datatype
			if (vType == "b")
				var fn = Boolean
			else if (vType == "n")
				var fn = Number
			else if (vType == "s")
				var fn = String
			else if (vType== "x")
				var fn = function(n) { return null; }
			
			currRoom.variables[vName] = fn(vVal)
		}
		
		// Populate Room userList
		for (var i = 0; i < userList.length; ++i)
		{
			// grab the user properties
			var name = userList[i].n.value
			var id   = userList[i].attributes.i
			var isMod = userList[i].attributes.m
			var isSpec = userList[i].attributes.s

			// set user Object (id, name ...)
			currRoom.userList[id] = new _ServerUser(id, name)
			currRoom.userList[id].isMod = (isMod == "1") ? true : false
			currRoom.userList[id].isSpec = (isSpec == "1") ? true : false
			
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
				if (vType == "b")
					var fn = Boolean
				else if (vType == "n")
					var fn = Number
				else if (vType == "s")
					var fn = String
				else if (vType== "x")
					var fn = function(n) { return null; }
				
				item[vName] = fn(vVal)
			}


		}
		
		// operation completed, release lock
		parent.changingRoom = false

		// Fire event!
		// Return a Room obj (with its id and name)
		parent.onJoinRoom(parent.roomList[roomId])
	}
	
	// joinKO => A problem was found when trying to join a room
	else if (action == "joinKO")
	{
		parent.changingRoom = false
		var error = xmlObj.error.attributes.msg
		parent.onJoinRoomError(error)
	}
	
	// userEntersRoom => a new user has joined the room
	else if (action == "userEnterRoom")
	{
		// Get user param
		var usrId 	= xmlObj.user.attributes.id
		var usrName 	= xmlObj.user.attributes.name
		
		// get current Room and populates usrList
		var currRoom	= parent.roomList[fromRoom]
		
		// add new client
		// 
		// Note:
		// a shortcut would to do 
		// currRoom.usrList[uid] = xmlObj.user.attributes
		//
		// because attributes = {id, name}
		
		currRoom.userList[usrId] = new _ServerUser(usrId, usrName)
		currRoom.userCount++
		
		// Point to the <vars></vars> node
		var userVars = xmlObj.user.vars.vars
		
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
			if (vType == "b")
				var fn = Boolean
			else if (vType == "n")
				var fn = Number
			else if (vType == "s")
				var fn = String
			else if (vType== "x")
				var fn = function(n) { return null; }
			
			item[vName] = fn(vVal)
		}
		
		parent.onUserEnterRoom(fromRoom, currRoom.userList[usrId])
	}
	
	// A user has left the room
	else if (action == "userGone")
	{
		//var roomId 	= xmlObj.user.attributes.r
		var usrId 		= xmlObj.user.attributes.id
		
		// get current Room
		var currRoom		= parent.roomList[fromRoom]
		var usrName		= currRoom.userList[usrId].name
		
		delete currRoom.userList[usrId]
		
		currRoom.userCount--
		
		// Send name and id to the application
		// because the user entry in the UserList has already been deleted
		
		parent.onUserLeaveRoom(fromRoom, usrId, usrName)
	}
	
	// You have a new public message
	else if (action == "pubMsg")
	{
		// sender id
		var usrId 	= xmlObj.user.attributes.id
		var textMsg	= xmlObj.txt.value
		var os	= new ObjectSerializer()
		
		textMsg	= os.decodeEntities(textMsg.toString())

		// fire event 
		parent.onPublicMessage(textMsg.toString(), parent.roomList[fromRoom].userList[usrId], fromRoom)
	}
	
	// You have a new private message
	else if (action == "prvMsg")
	{
		// sender id
		var usrId 	= xmlObj.user.attributes.id
		var textMsg	= xmlObj.txt.value
		var os		= new ObjectSerializer()

		textMsg		= os.decodeEntities(textMsg)

		// fire event 
		parent.onPrivateMessage(textMsg.toString(), parent.roomList[fromRoom].userList[usrId], fromRoom)
	}
	
	// You have a new Admin message
	else if (action == "dmnMsg")
	{
		// sender id
		var usrId 	= xmlObj.user.attributes.id
		var textMsg	= xmlObj.txt.value
		
		var os		= new ObjectSerializer()
		textMsg		= os.decodeEntities(textMsg)

		// fire event 
		parent.onAdminMessage(textMsg, parent.roomList[fromRoom].userList[usrId])
	}
	
	// You have a new AS Object
	else if (action == "dataObj")
	{
		var senderId 	= xmlObj.user.attributes.id
		var obj		= xmlObj.dataObj.value
			
		var os 		= new ObjectSerializer()
		var asObj	= os.deserialize(obj)
		
		parent.onObjectReceived(asObj, parent.roomList[fromRoom].userList[senderId])		


	}
	
	// A user has changed his/her variables
	else if (action == "uVarsUpdate")
	{
		var usrId 	= xmlObj.user.attributes.id
		var variables 	= xmlObj.vars.vars

		var user = parent.roomList[fromRoom].userList[usrId]
		
		if (user.variables == undefined)
			user.variables = {}
		
		for (var j = 0; j < variables.length; j++)
		{
			var vName = variables[j].attributes.n 
			var vType = variables[j].attributes.t
			var vVal  = variables[j].value
			
			if (vType == "x")
			{
				delete user.variables[vName]
			}
			else
			{
				// Dynamically cast the variable value to its original datatype
				if (vType == "b")
					var fn = Boolean
				else if (vType == "n")
					var fn = Number
				else if (vType == "s")
					var fn = String
				
				user.variables[vName] = fn(vVal)
			}	
		}
		
		parent.onUserVariablesUpdate(user)
	}
	
	// Notifies the roomVars update
	else if (action == "rVarsUpdate")
	{
		var variables 	= xmlObj.vars.vars
		
		var currRoom = parent.roomList[fromRoom]
		
		// A List of var names that changed in the last update
		var changedVars = []
		
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
				if (vType == "b")
					var fn = Boolean
				else if (vType == "n")
					var fn = Number
				else if (vType == "s")
					var fn = String

				currRoom.variables[vName] = fn(vVal)
			}
		}
		
		parent.onRoomVariablesUpdate(currRoom, changedVars)
	}
	
	// Room Create Request Failed
	else if (action == "createRmKO")
	{
		var errorMsg = xmlObj.room.attributes.e
		parent.onCreateRoomError(errorMsg)
	}
	
	// Receive and update about the user number in the other rooms
	else if (action == "uCount")
	{
		var uCount = xmlObj.attributes.u
		var sCount = xmlObj.attributes.s
		var room = parent.roomList[fromRoom]
		
		room.userCount = Number(uCount)
		room.specCount = Number(sCount)
		parent.onUserCountChange(room)
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
		
		var newRoom 	= new _ServerRoom(rmId, rmName, rmMax, rmSpec, isTemp, isGame, isPriv)
		
		parent.roomList[rmId] = newRoom
		
		var variables 	= xmlObj.rm.vars.vars
		
		// A List of var names that changed in the last update
		newRoom.variables = new Object()
		
		for (var j = 0; j < variables.length; j++)
		{
			var vName = variables[j].attributes.n 
			var vType = variables[j].attributes.t
			var vVal  = variables[j].value

			// Dynamically cast the variable value to its original datatype
			if (vType == "b")
				var fn = Boolean
			else if (vType == "n")
				var fn = Number
			else if (vType == "s")
				var fn = String
	
			newRoom.variables[vName] = fn(vVal)

		}
		
		parent.onRoomAdded(newRoom)
	}
	
	// A dynamic room was deleted
	else if (action == "roomDel")
	{
		var deletedId = xmlObj.rm.attributes.id
		
		var almostDeleted = parent.roomList[deletedId]
		
		delete parent.roomList[deletedId]
		
		parent.onRoomDeleted(almostDeleted)
		
	}
	
	// A room was left by the user
	// Used in multi-room mode
	else if (action == "leaveRoom")
	{
		var roomLeft = xmlObj.rm.attributes.id
		parent.onRoomLeft(roomLeft)
	}
	
	// RoundTrip response, for benchmark purposes only!
	else if (action == "roundTripRes")
	{
		parent.t2 = getTimer()
		parent.onRoundTripResponse((parent.t2 - parent.t1))
	}
	
	// Switch spectator response
	else if (action == "swSpec")
	{
		scope.playerId = Number (xmlObj.pid.attributes.id)
		
		parent.onSpectatorSwitched((scope.playerId > 0), scope.playerId, scope.roomList[fromRoom])
	}
	
	// full buddyList update
	else if (action == "bList")
	{
		var bList = xmlObj.bList.bList
		
		if (bList == undefined)
		{
			parent.onBuddyListError(xmlObj.err.value)
			return
		}
		
		for (var i = 0; i < bList.length; i++)
		{
			var buddy = {}
			
			buddy.isOnline 	= (bList[i].attributes.s == "1") ? true : false
			buddy.name 	= bList[i].n.value
			buddy.id	= bList[i].attributes.i
			buddy.variables	= {}
			
			var bVars = bList[i]["vs"].vs
			
			// Check buddy vars
			for (var j in bVars)
			{
				var vN = bVars[j].attributes.n
				var vV = bVars[j].value
				
				buddy.variables[vN] = vV
			}
			
			parent.buddyList.push(buddy)
		}
		
		parent.onBuddyList(parent.buddyList)
	}
	
	// buddyList update
	else if (action == "bUpd")
	{
		var b = xmlObj.b
		
		if (b == undefined)
		{
			parent.onBuddyListError(xmlObj.err.value)
			return
		}
		
		var buddy = {}
		buddy.name = b.n.value
		buddy.id = b.attributes.i
		buddy.isOnline = (b.attributes.s == "1") ? true : false
		buddy.variables = {}
		
		var bVars = b["vs"].vs
			
		// Check buddy vars
		for (var i in bVars)
		{
			var vN = bVars[i].attributes.n
			var vV = bVars[i].value
			
			buddy.variables[vN] = vV
		}
		
		// Search for buddy item and overwrite it
		for (var i = 0; i < parent.buddyList.length; i++)
		{
			if (parent.buddyList[i].name == buddy.name)
			{
				parent.buddyList[i] = buddy
				break
			}
		}
		
		parent.onBuddyListUpdate(buddy)
	}
	
	// buddyList Add ::HIDDEN::
	else if (action == "bAdd")
	{
		var b = xmlObj.b
		
		var buddy = {}
		buddy.name = b.value
		buddy.id = b.attributes.i
		buddy.isOnline = (b.attributes.s == "1") ? true : false
		buddy.variables = {}
		
		var bVars = b["vs"].vs
			
		// Check buddy vars
		for (var i in bVars)
		{
			var vN = bVars[i].attributes.n
			var vV = bVars[i].value
			
			buddy.variables[vN] = vV
		}
		
		parent.buddyList.push(buddy)
		
		// Fire event
		parent.onBuddyList(parent.buddyList)
	}
	
	// buddyList update
	else if (action == "roomB")
	{
		var roomIds = xmlObj.br.attributes.r
		
		var ids = roomIds.toString().split(",")
		
		for (var i in ids)
			ids[i] = Number(ids[i])
			
		parent.onBuddyRoom(ids)
	}
	
	// handle the randomKey reception
	else if (action == "rndK")
	{
		var k = xmlObj.k.value
		parent.onRandomKey(k)
	}
}



//-----------------------------------------------------------------------------------//
// Extension Messages Handler
// 
// TODO: by default if type is omitted then >>> type = "xml"
//-----------------------------------------------------------------------------------//
SmartFoxClient.prototype.handleExtensionMessages = function(xmlObj, parent, type)
{
	// Handle and XML formatted object
	if (type == "xml")
	{
		// get "action" and "r" attributes
		var action 		= xmlObj.attributes.action
		var fromRoom 		= xmlObj.attributes.r
		
		if (action == "xtRes")
		{
			//var senderId 	= xmlObj.user.attributes.id
			//var obj		= xmlObj.dataObj.value
			var obj		= xmlObj.value
				
			var os 		= new ObjectSerializer()
			var asObj	= os.deserialize(obj)
			
			parent.onExtensionResponse(asObj, "xml")		
		}
	}
	
	// Handle string formatted message
	else if (type == "str")
	{
		parent.onExtensionResponse(xmlObj, type)
	}
	
}



//-----------------------------------------------------------------------------------//
// Send a message to a server extension
//
// xtName 	= unique name of the extension
// cmdName 	= the command to execute
// paramObj	= an object with the params for this command 
// type		= can be "xml" or "str" in order to decide which protocol to use
// [roomId]	= (optional) the roomId, if using multirooms
//-----------------------------------------------------------------------------------//
SmartFoxClient.prototype.sendXtMessage = function(xtName, cmdName, paramObj, type, roomId)
{
	if (roomId == undefined)
		roomId = this.activeRoomId
	
	// XML is default
	if (type == undefined)
		type = "xml"
	
	if (type == "xml")
	{
		var header 	= {t:"xt"}
		var os 	= new ObjectSerializer()
		
		// Encapsulate message
		var xtReq 	= {name: xtName, cmd: cmdName, param: paramObj}
		//var xmlmsg 	= "<dataObj><![CDATA[" + os.serialize(xtReq) + "]]></dataObj>"
		var xmlmsg 	= "<![CDATA[" + os.serialize(xtReq) + "]]>"
		
		this.send(header, "xtReq", roomId, xmlmsg)
	}
	else if (type == "str")
	{
		var header = "%xt%" + xtName + "%" + cmdName + "%" + roomId + "%"
		
		for (var i=0; i < paramObj.length; i++)
			header += paramObj[i].toString() + "%"
		
		this.sendString(header)
	}
	
}



//-----------------------------------------------------------------------------------
// Debug ONLY
//-----------------------------------------------------------------------------------
SmartFoxClient.prototype.dumpObj = function(obj)
{
	if (this.debug)
	{
		trace("------------------------------------------------")
		trace("+ Object Dump                                  +")
		trace("------------------------------------------------")
		trace("Obj TYPE:" + typeof obj)
		
		for (var i in obj)
			trace(i + " > " + obj[i])

	}
}



//-----------------------------------------------------------------------------------//
// Send a [PUBLIC] text message to the users
// msg 	= the txt
// roomId	= (OPTIONAL) the id of the room, if working with multirooms
//-----------------------------------------------------------------------------------//
SmartFoxClient.prototype.sendPublicMessage = function(msg, roomId)
{
	if (roomId == undefined)
		roomId = this.activeRoomId
		
	var header 	= {t:"sys"}
	var os 	= new ObjectSerializer()
	
	var xmlmsg 	= "<txt><![CDATA[" + os.encodeEntities(msg) + "]]></txt>"

	this.send(header, "pubMsg", roomId, xmlmsg)
	
}



//-----------------------------------------------------------------------------------//
// Send a [PRIVATE] text message to one user
// msg 	= the txt
// userId	= the id of the recipient user
// roomId	= (OPTIONAL) the id of the room, if working with multirooms
//-----------------------------------------------------------------------------------//
SmartFoxClient.prototype.sendPrivateMessage = function(msg, userId, roomId)
{
	if (roomId == undefined)
		roomId = this.activeRoomId
		
	var header 	= {t:"sys"}
	var os 	= new ObjectSerializer()
	
	var xmlmsg 	= "<txt rcp='" + userId + "'><![CDATA[" + os.encodeEntities(msg) + "]]></txt>"

	this.send(header, "prvMsg", roomId, xmlmsg)
	
}



//-----------------------------------------------------------------------------------//
// Serialize Actionscript Object and send it
// Requires ObjectSerializerClass
//-----------------------------------------------------------------------------------//
SmartFoxClient.prototype.sendObject = function(obj, roomId)
{
	// If roomId is passed then use it
	// otherwise just use the current active room id
	if (roomId == undefined)
		roomId = this.activeRoomId
		
		
	var os = new ObjectSerializer()
	
	var xmlPacket = "<![CDATA[" + os.serialize(obj) + "]]>"
	
	var header 	= {t:"sys"}

	this.send(header, "asObj", roomId, xmlPacket)
}


//-----------------------------------------------------------------------------------//
// Serialize Actionscript Object and send it to a list of recipients
//-----------------------------------------------------------------------------------//
SmartFoxClient.prototype.sendObjectToGroup = function(obj, userList, roomId)
{
	if (roomId == undefined)
		roomId = this.activeRoomId
			
	var _$$_ = ""
	
	for (var i in userList)
	{
		if (!isNaN(userList[i]))
			_$$_ += userList[i] + ","
	}
	
	_$$_ = _$$_.substr(0, _$$_.length - 1)
	obj._$$_ = _$$_
	
	var os = new ObjectSerializer()
	
	var xmlPacket = "<![CDATA[" + os.serialize(obj) + "]]>"
	var header = {t:"sys"}
	
	this.send(header, "asObjG", roomId, xmlPacket)
}

//
// Create / Update user variables on server
// the varObj is an Objects of variables
// 
// Ex:
// vObj = new Object
// vObj.name = "test"
// vObj.score= 1000
// 
// setUserVariables (vObj)
//
SmartFoxClient.prototype.setUserVariables = function(varObj, roomId)
{
	if (roomId == undefined)
		roomId = this.activeRoomId
		
	var header = {t:"sys"}
	
	// Encapsulate Variables
	var xmlmsg = "<vars>"
	
	var user = this.roomList[roomId].userList[this.myUserId]
	
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
	
	xmlmsg += "</vars>"

	this.send(header, "setUvars", roomId, xmlmsg)
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
SmartFoxClient.prototype.createRoom = function (roomObj, rId)
{
	var roomId		= (rId == undefined) ? this.activeRoomId : rId
	var header 		= {t:"sys"}
		
	var updatable 		= (roomObj.updatable) ? 1 : 0
	var isGame 		= (roomObj.isGame) ? 1 : 0
	var exitCurrent		= 1
	var maxSpectators	= roomObj.maxSpectators
	
	// If this is a Game Room you will leave the current room
	// and log into the new game room
	// If you specify exitCurrentRoom = false you will not be logged out of the curr room.
	if (isGame && roomObj.exitCurrentRoom != undefined)
	{
		exitCurrent	= (roomObj.exitCurrentRoom) ? 1:0
	}
	
	xmlMsg  = "<room upd='" + updatable + "' tmp='1' gam='" + isGame + "' spec='" + maxSpectators + "' exit='" + exitCurrent + "'>"
	
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
	{
		xmlMsg += "<vars></vars>"
	}
	else
	{
		xmlMsg += "<vars>"
		
		for (var i in roomObj.vars)
		{
			xmlMsg += this.getXmlRoomVariable(roomObj.vars[i])
		}
		
		xmlMsg += "</vars>"
	}
	
	xmlMsg += "</room>"
		
	this.send(header, "createRoom", roomId, xmlmsg)
}


//-----------------------------------------------------------------------------------
//  Leave a room
//  Can be used when a client is connected in more than one room at a time
//  If the user is connected in one room only this command will have no effect
//-----------------------------------------------------------------------------------
SmartFoxClient.prototype.leaveRoom = function(roomId)
{
	var header = {t:"sys"}
	var xmlMsg = "<rm id='" + roomId + "' />"
	
	this.send(header, "leaveRoom", roomId, xmlMsg)
}


//-----------------------------------------------------------------------------------
//  Search for a room
//  you can pass as the roomId, both its numeric Id or its name
//-----------------------------------------------------------------------------------
SmartFoxClient.prototype.getRoom = function(roomId)
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
SmartFoxClient.prototype.getActiveRoom = function()
{
	return this.roomList[this.activeRoomId]
}



//-----------------------------------------------------------------------------------
// Set variables for a Room on the server side
//-----------------------------------------------------------------------------------
SmartFoxClient.prototype.setRoomVariables = function(varObj, roomId, setOwnership)
{
	if (roomId == undefined)
		roomId = this.activeRoomId
		
	if (setOwnership == undefined)
		setOwnership = true
		
	var header 	= {t:"sys"}
	
	// Encapsulate Variables
	// so (setOwnership) attribute is sent only if specified as false
	if (setOwnership)
		var xmlMsg = "<vars>"
	else
		var xmlMsg = "<vars so='0'>"
	
	for (var i = 0; i < varObj.length; i++)
	{
		xmlMsg += this.getXmlRoomVariable(varObj[i])
	}
	
	xmlMsg += "</vars>"

	this.send(header, "setRvars", roomId, xmlmsg)
}



//-----------------------------------------------------------------------------------
// Add a buddy to the buddyList
//-----------------------------------------------------------------------------------
SmartFoxClient.prototype.loadBuddyList = function()
{
	var header = {t:"sys"}
	this.send(header, "loadB", -1, "")
}


//-----------------------------------------------------------------------------------
// Add a buddy to the buddyList
//-----------------------------------------------------------------------------------
SmartFoxClient.prototype.addBuddy = function(buddyName)
{
	if (buddyName != this.myUserName && !this.checkBuddy(buddyName))
	{
		
		// Look for userId
		var id = this.roomList[this.activeRoomId].getUserList().getUser(buddyName)
			
		// Send buddy to server
		var header = {t:"sys"}
		var xmlMsg = "<n>" + buddyName + "</n>"
		
		this.send(header, "addB", -1, xmlMsg)
	}
}



//-----------------------------------------------------------------------------------
// Removes a buddy from the buddyList
//-----------------------------------------------------------------------------------
SmartFoxClient.prototype.removeBuddy = function(buddyName)
{
	//var buddy

	for (var i in this.buddyList)
	{
		if (this.buddyList[i].name == buddyName)
		{
			delete this.buddyList[i]
			break
		}
	}
	
	var header = {t:"sys"}
	var xmlMsg = "<n>" + buddyName + "</n>"
		
	// Send 
	this.send(header, "remB", -1, xmlMsg)
		
	this.onBuddyList(this.buddyList)
}

SmartFoxClient.prototype.getBuddyRoom = function(buddy)
{
	// If buddy is active...	
	if (buddy.id != -1)
		this.send({t:"sys", bid:buddy.id}, "roomB", -1, "<b id='" + buddy.id + "' />")
}

//-----------------------------------------------------------------------------------
// Checks if a buddy already exist
//-----------------------------------------------------------------------------------
SmartFoxClient.prototype.checkBuddy = function(name)
{
	var res = false
	
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
SmartFoxClient.prototype.clearBuddyList = function()
{
	this.buddyList = []
	
	this.send({t:"sys"}, "clearB", -1, "")
	
	this.onBuddyList(this.buddyList)
}


//-----------------------------------------------------------------------------------
// Returns the XML representation of a RoomVariable
// 
// used by CreateRoom() and setRoomVariables()
//-----------------------------------------------------------------------------------
SmartFoxClient.prototype.getXmlRoomVariable = function(rVar)
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




SmartFoxClient.prototype.roundTripBench = function()
{
	this.t1 	= getTimer()
	
	var header 	= {t:"sys"}
	this.send(header, "roundTrip", this.activeRoomId, "")
}


// Turn a spectator into a player
SmartFoxClient.prototype.switchSpectator = function(roomId)
{
	if (roomId == undefined)
		roomId = this.activeRoomId
	
	var header = {t:"sys"}
	this.send(header, "swSpec", roomId, "")
}




SmartFoxClient.prototype.login = function(zone, nick, pass)
{
	var header 	= {t:"sys"}
	var message 	= "<login z='" + zone + "'><nick><![CDATA[" + nick + "]]></nick><pword><![CDATA[" + pass + "]]></pword></login>"

	this.send(header, "login", 0, message)
}



//-----------------------------------------------------------------------------------
// Request autoJoin in defaultRoom
//-----------------------------------------------------------------------------------
SmartFoxClient.prototype.autoJoin = function()
{
	var header 	= {t:"sys"}
	this.send(header, "autoJoin", (this.activeRoomId ? this.activeRoomId:"-1") , "")
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
SmartFoxClient.prototype.joinRoom = function(newRoom, pword, isSpectator, dontLeave, oldRoom)
{
	var newRoomId = null
	var isSpec
		
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

				if (this.roomList[i].name == newRoom)
				{
					newRoomId = this.roomList[i].id
					break
				}
			}
		}
		
		if (newRoomId != null)
		{
			var header 	= {t:"sys"} 
			
			var leaveCurrRoom = (dontLeave) ? "0": "1"
			
			// Send oldroom id, even if you don't want to disconnect
			if (oldRoom)
				var roomToLeave = oldRoom			
			else
				var roomToLeave = this.activeRoomId
		
			// CHECK:
			// if this.activeRoomId is null no room has already been entered
			if (this.activeRoomId == null)
			{
				leaveCurrRoom = 0
				roomToLeave = -1
			}
			
			var message 	= "<room id='" + newRoomId + "' pwd='" + pword + "' spec='" + isSpec + "' leave='" + leaveCurrRoom + "' old='" + roomToLeave + "' />"
			
			this.send(header, "joinRoom", ((this.activeRoomId) ? this.activeRoomId:-1), message)
			this.changingRoom = true
		}
		else
		{
			trace("SmartFoxError: requested room does not exist!")
		}
	}
}



//-----------------------------------------------------------------------------------
// Request Room List
//-----------------------------------------------------------------------------------
SmartFoxClient.prototype.getRoomList = function()
{
	var header 	= {t:"sys"}
	this.send(header, "getRmList", (this.activeRoomId ? this.activeRoomId:"-1"), "")
}



SmartFoxClient.prototype.send = function(header, action, fromRoom, message)
{
	// Setup Msg Header
	var xmlMsg = this.makeHeader(header);
	
	// Setup Body
	xmlMsg += "<body action='" + action + "' r='" + fromRoom + "'>" + message + "</body>" + this.closeHeader()

	if (this.debug)
		trace("[Sending]: " + xmlMsg + newline)

	this.server.send(xmlMsg)
}



//-----------------------------------------------------------------------------------
// sendString sends a string formatted message instead of an XML one
// The string is separated by "%" characters
// The first two fields are mandatory:
//
// % handlerId % actionName % param % param % ... % ... %
//-----------------------------------------------------------------------------------
SmartFoxClient.prototype.sendString = function(message)
{
	if (this.debug)
		trace("[Sending]: " + message + newline)
				
	this.server.send(message)
}



//-----------------------------------------------------------------------------------
// Warning: this is in the scope of the server object inside the SmartFoxClient Object
// Always use this.parent object to go backt to SmartFoxClient level
//-----------------------------------------------------------------------------------
SmartFoxClient.prototype.xmlReceived = function(message)
{
	var xmlObj = new Object();

	this.parent.message2Object(message.childNodes, xmlObj, this.parent)

	if (this.parent.debug)
		trace("[Received]: " + message)

	// get Handler
	var id = xmlObj.msg.attributes.t

	this.parent.messageHandlers[id].handleMessage(xmlObj.msg.body, this.parent, "xml")
}



//-----------------------------------------------------------------------------------
// Handle string message from server
//-----------------------------------------------------------------------------------
XMLSocket.prototype.strReceived = function(message)
{
	var params = message.substr(1, message.length - 2).split("%")

	if (this.parent.debug)
		trace("[Received]: " + message + newline)
	
	// get Handler
	var id = params[0]
	
	// the last parameter specify that we have a string formatted message
	this.parent.messageHandlers[id].handleMessage(params.splice(1, params.length -1), this.parent, "str")
}



SmartFoxClient.prototype.connect = function(serverIp, serverPort)
{
	// keep a reference to "this" object
	this.server.parent		= this
	this.server.onXML		= this.xmlReceived
	
	this.server.onConnect 		= this.connectionEstablished
	this.server.onClose		= this.onClose

	this.server.connect(serverIp, serverPort)
}


SmartFoxClient.prototype.connectionEstablished = function(ok)
{
	if (ok)
	{
		var xmlMsg = "<msg t='sys'><body action='verChk' r='0'><ver v='" + this.parent.majVersion.toString() + this.parent.minVersion.toString() + this.parent.subVersion.toString() + "' /></body></msg>"	
		
		if (this.parent.debug)
			trace("[ Sending ]: " + xmlMsg)
		
		this.send(xmlMsg)
	}
	else
		this.parent.onConnection(false)
}


SmartFoxClient.prototype.disconnect = function()
{
	this.server.close()
	this.onConnectionLost()
}

SmartFoxClient.prototype.onClose = function()
{
	// Fire client event
	this.parent.onConnectionLost()
}

SmartFoxClient.prototype.getRandomKey = function()
{
	this.send({t:"sys"}, "rndK", -1, "")
}


//
// Create / Update Buddy Variables on server
// the varObj is an Objects of variables
//
SmartFoxClient.prototype.setBuddyVariables = function(varObj)
{			
	var header = {t:"sys"}
	
	// Encapsulate Variables
	var xmlMsg = "<vars>"
	
	// Reference to the user setting the variables
	
	for (var vName in varObj)
	{
		var vValue = varObj[vName]
		
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
SmartFoxClient.prototype.dumpRoomList = function()
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



//----------------------------------------------------------------
// XML Helper Functions
//----------------------------------------------------------------

//-------------------------------------------------------
// Message Parser :
// parses the xml message into an Actionscript Object
//
// Retrieve attributes = xmlObj.node.attributes.attrName
// Retrieve tag value  = xmlObj.node.value
//-------------------------------------------------------
SmartFoxClient.prototype.message2Object = function (xmlNodes, parentObj, parent)
{
	// counter
	var i = 0
	var currObj = null

	while(i < xmlNodes.length)
	{
		// get first child inside XML object
		var node 	= xmlNodes[i]
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
			parentObj[nodeName] = {}
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
			var currObj = currObj[nodeName]
		}

		// Check if we have more subnodes
		if (node.hasChildNodes() && node.firstChild.nodeValue == undefined)
		{
			// Call this function recursively until node has no more children
			var subNodes = node.childNodes
			parent.message2Object(subNodes, currObj, parent)
		}
		else
		{
			var nodeValue = node.firstChild.nodeValue

			if (!isNan(nodeValue) && node.nodeName != "txt")
				nodeValue = Number(nodeValue)

			currObj.value = nodeValue
		}

		i++
	}

}



SmartFoxClient.prototype.makeHeader = function (headerObj)
{
	var xmlData = "<msg"

	for (var item in headerObj)
	{
		xmlData += " " + item + "='" + headerObj[item] + "'"
	}

	xmlData += ">"

	return xmlData
}



SmartFoxClient.prototype.closeHeader = function ()
{
	return "</msg>"
}



//====================================================================================================
//====================================================================================================
//====================================================================================================
//====================================================================================================




/*
	Actionscript 1.0 Object Serializer / DeSerializer
	version 2.7
	
	Supports:
	--------------------------------------------------
	primitive datatypes: null, boolean, number, string
	object datatypes: object, array
	
	Last update: November 25th 2004
*/


_global.ObjectSerializer = function()
{
	this.tabs 	= "\t\t\t\t\t\t\t\t\t\t"			// used for debug only, for xml formatting
	this.xmlStr 	= ""						// the final XML text of the serialized obj
	this.debug 	= false						// if true, formats XML in human readable style
	this.eof	= ""						// end of line constant, used only for debug
	
	this.hexTable 	= new Array()
	
	//--- XML Entities Conversion table ----------------------
	this.ascTab			= []
	this.ascTab[">"] 		= "&gt;"
	this.ascTab["<"] 		= "&lt;"
	this.ascTab["&"] 		= "&amp;"
	this.ascTab["'"] 		= "&apos;"
	this.ascTab["\""] 		= "&quot;"
	
	this.ascTabRev		= []
	this.ascTabRev["&gt;"]	= ">"
	this.ascTabRev["&lt;"] 	= "<"
	this.ascTabRev["&amp;"] 	= "&"
	this.ascTabRev["&apos;"] 	= "'"
	this.ascTabRev["&quot;"] 	= "\""
	
	// Char codes in the upper Ascii range
	/*
	for (var i = 127; i <= 255; i++)
	{
		this.ascTab[i] = "&#x"+i.toString(16)+";"
		
		this.ascTabRev["&#x"+i.toString(16)+";"] = chr(i);
	}*/
	
	this.hexTable = new Array()
	this.hexTable["0"] = 0
	this.hexTable["1"] = 1
	this.hexTable["2"] = 2
	this.hexTable["3"] = 3
	this.hexTable["4"] = 4
	this.hexTable["5"] = 5
	this.hexTable["6"] = 6
	this.hexTable["7"] = 7
	this.hexTable["8"] = 8
	this.hexTable["9"] = 9
	this.hexTable["A"] = 10
	this.hexTable["B"] = 11
	this.hexTable["C"] = 12
	this.hexTable["D"] = 13
	this.hexTable["E"] = 14
	this.hexTable["F"] = 15
	
}



ObjectSerializer.prototype.serialize = function(obj)
{
	this.xmlStr 	= ""
	
	if (this.debug) 
		this.eof = "\n"
	
	this.obj2xml(obj, 0, "")					// Call serializer recursively
	
	return this.xmlStr						// returns the XML text
}



ObjectSerializer.prototype.obj2xml = function(obj, lev, objn)
{
	
	// Open root TAG
	// <dataObject></dataObject>
	if (lev == 0)
		this.xmlStr += "<dataObj>" + this.eof
	else
	{
		if (this.debug)
			this.xmlStr += this.tabs.substr(0, lev) 
		
		// Object type
		var ot = (obj instanceof Array) ? "a" : "o"

		this.xmlStr += "<obj t='" + ot + "' o='" + objn + "'>" + this.eof
	}
	
	// Scan the object recursively
	for (var i in obj)
	{
		var t 	= typeof obj[i]
		var o 	= obj[i]		
		
		//
		// if a primitive type is found
		// generate an xml <var n="name" t="type">value</var> TAG
		//
		// n = name of var
		//
		// t = b: boolean
		//     n: number
		//     s: string
		//     x: null
		//
		// v = value of var
		//
		if ((t == "boolean") || (t == "number") || (t == "string") || (t == "null"))
		{	
			if (t == "boolean")
			{
				o = Number(o)
			}
			else if (t == "null")
			{
				t = "x"
				o = ""
			}
			else if (t == "string")
			{
				o = this.encodeEntities(o)
			}
			
			if (this.debug)
				this.xmlStr += this.tabs.substr(0, lev+1)
			
			this.xmlStr += "<var n='" + i + "' t='" + t.substr(0,1) + "'>" + o + "</var>" + this.eof
		}
		
		//
		// if an object / array is found
		// recursively scans the new Object
		// and create a <obj o=""></obj> TAG
		//
		// o = object name
		//
		else if (t == "object")
		{
			this.obj2xml(o, lev + 1, i)
			
			if (this.debug)
				this.xmlStr += this.tabs.substr(0, lev + 1)

			this.xmlStr += "</obj>" + this.eof
		}
	}
	
	// Close root TAG
	if (lev == 0)
		this.xmlStr += "</dataObj>" + this.eof
}



ObjectSerializer.prototype.deserialize = function(xmlObj)
{
	this.xmlData 			= new XML(xmlObj)		// xml Object
	this.xmlData.ignoreWhite 	= true				// this does not work as it is declared AFTER the XML Object is populated
	this.resObj  			= {}				// internal result Object

	this.xml2obj(this.xmlData, this.resObj)				// calls recursive xml parser
	
	return this.resObj						// Delete local object
}



ObjectSerializer.prototype.xml2obj = function(xmlNode, currObj)
{
	// counter
	var i = 0
	
	// take first child inside XML object
	var node = xmlNode.firstChild
	
	// Main recursion loop
	while(node.childNodes[i])
	{	
		// If an object definition is found
		// create the new Object in the current Object and recursively scan the xml data
		if (node.childNodes[i].nodeName == "obj")
		{
			// Get Object name
			var n = node.childNodes[i].attributes.o
			
			// Get Object type
			var ot = node.childNodes[i].attributes.t
		
			
			// Create the right type of Object
			if (ot == "a")
				currObj[n] = []
			else if (ot == "o")
				currObj[n] = {}
				
			// Recursion
			this.xml2obj(new XML(node.childNodes[i]), currObj[n]);
		} 
		
		// If a primitive type is found
		// create the variable inside the current Object casting its value to the original datatype
		else
		{
			// Found a variable
			var n = node.childNodes[i].attributes.n
			var t = node.childNodes[i].attributes.t
			var v = node.childNodes[i].firstChild.nodeValue
			
			// Dynamically cast the variable value to its original datatype
			if (t == "b")
				var fn = Boolean
			else if (t == "n")
				var fn = Number
			else if (t == "s")
				var fn = String
			else if (t == "x")
				var fn = function(n) { return null; }


			currObj[n] = fn(v)
			
			/*
			if (fn == String)
				currObj[n] = this.decodeEntities(currObj[n]) */
		}
		
		// next xml node
  		i++;
	}
}



//---------------------------------------------------------
// Helper functions
// v 1.0
// November 25th 2004
//---------------------------------------------------------

ObjectSerializer.prototype.encodeEntities = function(st)
{
	var strbuff = ""
	
	// char codes < 32 are ignored except for tab,lf,cr
	
	for (var i=0; i < st.length; i++)
	{
		var ch = st.charAt(i)
		var cod = st.charCodeAt(i)
		
		if (cod == 9 || cod == 10 || cod == 13)
		{
			strbuff += ch
		}
		else if (cod >= 32 && cod <=126)
		{
			if (this.ascTab[ch] != undefined)
			{
				strbuff += this.ascTab[ch]
			}
			else
				strbuff += ch
		}
		/*
			else if (cod > 126 && cod <= 255)
			{
				strbuff += this.ascTab[cod]
			}
			else if (cod > 255)
			{
				strbuff += "&#x" + cod.toString(16) + ";"
			}*/
		else
			strbuff += ch

	}

	return strbuff
}



ObjectSerializer.prototype.decodeEntities = function(st)
{
	var strbuff = ""
	var i = 0
	var item
	
	while(i < st.length)
	{
		var ch = st.charAt(i)
		
		if (ch == "&")
		{
			var ent = ch
			
			// read the complete entity
			do
			{
				i++
				var chi = st.charAt(i)
				ent += chi	
			} 
			while (chi != ";")
				
			item = this.ascTabRev[ent]

			if (item != undefined)
				strbuff += item
			else
				strbuff += String.fromCharCode(this.getCharCode(ent))
		}
		else
			strbuff += ch
			
		i++
	}

	return strbuff
}


//-----------------------------------------------
// Transform xml code entity into hex code
// and return it as a number
//-----------------------------------------------
ObjectSerializer.prototype.getCharCode = function(ent)
{
	var hex = ent.substr(3, ent.length)	
	hex = hex.substr(0, hex.length - 1)
	
	return Number("0x" + hex)
}





/*
* --- ServerRoom private class ------------------------------------------------------
* 
* id 		= room unique id
* name		= room name (can be used as key as well)
* maxUsers	= max capacity
* temp		= isTemp (true if the room is temporary)
* game		= isGame (true if the room holds a game)
* priv		= isPrivate (if true, user mus provide a password to join it)
*
* updatable	= not yet implemented
* description	= not yet implemented
* 
* userList	= a list of _ServerUser objects
* variables	= a list of room variables
* 
* ------------------------------------------------------------------------------------
*/
function _ServerRoom(id, name, maxUsers, maxSpectators, isTemp, isGame, isPrivate)
{
	this.id			= id
	this.name 		= name
	this.maxUsers 		= maxUsers
	this.maxSpectators	= maxSpectators
	this.temp 		= isTemp
	this.game 		= isGame
	this.priv 		= isPrivate
	this.limbo		= false
	
	this.updatable 		= false
	this.description 	= ""
	this.userCount 		= 0
	
	this.userList		= new Object()
	this.variables		= new Array()
	
	this.myPlayerIndex	= null
	
}


//-----------------------------------------------------------------------------------
// Return the userList
//-----------------------------------------------------------------------------------
_ServerRoom.prototype.getUserList = function()
{
	return this.userList
}



/*
* Return the user specified, if exist
* userId can be the unique user Id, or the user name as well
*/
_ServerRoom.prototype.getUser = function(userId)
{
	if (typeof userId == "number")
	{
		return this.userList[userId]
	}
	else if (typeof userId == "string")
	{
		for (var i in this.userList)
		{
			var u = this.userList[i]			
		}
	}
}


//-----------------------------------------------------------------------------------
// Return a variable
//-----------------------------------------------------------------------------------
_ServerRoom.prototype.getVariable = function(varName)
{
	return this.variables[varName]
}

_ServerRoom.prototype.getVariables = function()
{
	return this.variables
}

//-----------------------------------------------------------------------------------
// Get the roomName
//-----------------------------------------------------------------------------------
_ServerRoom.prototype.getName = function()
{
	return this.name
}

_ServerRoom.prototype.getId = function()
{
	return this.id
}

_ServerRoom.prototype.isTemp = function()
{
	return this.temp
}

_ServerRoom.prototype.isGame = function()
{
	return this.game
}

_ServerRoom.prototype.isPrivate = function()
{
	return this.priv
}

_ServerRoom.prototype.getUserCount = function()
{
	return this.userCount
}

_ServerRoom.prototype.getMaxUsers = function()
{
	return this.maxUsers
}

_ServerRoom.prototype.getMaxSpectators = function()
{
	return this.maxSpectators
}

// Set the myPlayerId
// Each room where the current client is connected contains a myPlayerId
// if the room is a gameRoom
//
// myPlayerId == -1 ... user is a spectator
// myPlayerId  > 0  ...	user is a player
_ServerRoom.prototype.setMyPlayerIndex = function(id)
{
	this.myPlayerIndex = id
}


// Returns my player id for this room
// Usefull when dealing with multi-room applications
_ServerRoom.prototype.getMyPlayerIndex = function()
{
	return this.myPlayerIndex
}

_ServerRoom.prototype.setIsLimbo = function(b)
{
	this.limbo = b
}

_ServerRoom.prototype.isLimbo = function()
{
	return this.limbo
}


/*
* Server User Object
* 
* id		= unique user id
* name		= unique user name (can be used as a key as well)
* variables 	= an object with all user variables
* 
*/

function _ServerUser(id, name)
{
	this.id = id
	this.name = name
	this.variables = new Object()
	this.isSpec = false
	this.isMod = false
}

_ServerUser.prototype.getId = function()
{
	return this.id
}

_ServerUser.prototype.getName = function()
{
	return this.name
}

_ServerUser.prototype.getVariable = function(varName)
{
	return this.variables[varName]
}

_ServerUser.prototype.getVariables = function()
{
	return this.variables
}

_ServerUser.prototype.setIsSpectator = function(b)
{
	this.isSpec = b
}
	
_ServerUser.prototype.isSpectator = function()
{
	return this.isSpec
}

_ServerUser.prototype.isModerator = function()
{
	return this.isMod
}

