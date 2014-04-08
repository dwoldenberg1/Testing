#include "SmartFoxClient.as"

function ServerSF() {
	
	this.sf = new SmartFoxClient ();
	this.sf.parent = this;
	
	
	
	
	
	/* PROPERTIES */
	
	this.isConnectedVar = false;
	this.isConnected = function () {
		return this.isConnectedVar;
	}
	
	this.password = es.password;
	
	this.username = this.sf.myUserName;
	
	
	
	
	
	/* METHODS */
	
	this.connect = function (ip, port) {
		if (ip == undefined) ip = this.ip;
		if (port == undefined) port = this.port;
		this.sf.connect (ip, Number(port));
	}
	
	this.setIP = function (ip) {
		this.ip = ip;
	}
	
	this.setPort = function (port) {
		this.port = port;
	}
	
	this.login = function (username, password) {
		this.sf.login ("TheoChat", username, password);
		this.username = username;
		this.password = password;
	}
	
	this.createRoom = function (Room_object, auto_join) {
		if (Room_object.roomName != "Lobby") {
			var created = false;
			for (i in this.sf.roomList) {
				if (this.sf.roomList[i].getName () == Room_object.roomName) {
					this.sf.joinRoom (this.sf.roomList[i].getId ());
					created = true;
					break;
				}
			}
			if (!created) {
				room = new Object ();
				room.name = Room_object.roomName;
				room.isGame = false;
				room.maxUsers = 15;
				this.sf.createRoom (room);
			}
		} else {
			this.joinLobby = true;
			this.sf.getRoomList ();
		}
	}
	
	this.joinRoom = function (room, password, zone) {
		this.sf.joinRoom (room, password);
	}
	
	this.getRoomList = function () {
		var rl = new Array ();
		for (i in this.sf.roomList) {
			if (typeof (this.sf.roomList[i]) == "object") {
				rl[rl.length] = new Object ();
				rl[rl.length - 1].name = new Object ();
				rl[rl.length - 1].name.value = this.sf.roomList[i].getName ();
				rl[rl.length - 1].attributes = new Object ();
				rl[rl.length - 1].attributes.users = this.sf.roomList[i].getUserCount ();
				rl[rl.length - 1].attributes.maxCapacity = this.sf.roomList[i].getMaxUsers ();
				rl[rl.length - 1].attributes.IsPasswordProtected = this.sf.roomList[i].isPrivate ();
				rl[rl.length - 1].id = this.sf.roomList[i].getId ();
			}
		}
		return rl;
	}
	
	this.getRoomVariables = function () {
		return this.sf.getActiveRoom ().getVariables ();
	}
	
	this.getUserList = function () {
		var ul = new Array ();
		var sful = this.sf.getActiveRoom ().getUserList ();
		for (var i in sful) {
			if (typeof (sful[i]) == "object") {
				ul[ul.length] = new Object ();
				ul[ul.length - 1].name = new Object ();
				ul[ul.length - 1].name.value = sful[i].getName ();
				ul[ul.length - 1].attributes = new Object ();
				ul[ul.length - 1].attributes.moderator = sful[i].getVariables ().isMod;
				ul[ul.length - 1].userVariables = sful[i].getVariables ();
				ul[ul.length - 1].id = sful[i].getId ();
			}
		}
		return ul;
	}
	
	this.getRoomById = function (id) {
		var rl = this.getRoomList ();
		for (var i = 0; i < rl.length; i++)
			if (rl[i].id == id) return rl[i];
	}
	
	this.getZone = function () {
		var rl = this.getRoomList ();
		var numUsers = 0;
		for (var i = 0; i < rl.length; i++)
			numUsers += rl[i].attributes.users;
		var obj = new Object ();
		obj.name = "TheoChat";
		obj.numUsers = numUsers;
		return obj;
	}
	
	this.createUserVariable = function (name, value, update) {
		var ul = this.getUserList ();
		var myId = this.sf.myUserId;
		trace (myId);
		for (var i=0; i<ul.length; i++)
			if (ul[i].id == myId) {
				var obj = ul[i].userVariables;
				obj.isMod = this.sf.isModerator ();
				if (typeof(obj[name]) == "undefined") obj.lastAction = "created";
				else obj.lastAction = "updated";
				obj[name] = value;
				obj.lastActionTarget = name;
				this.sf.setUserVariables (obj);
				break;
			}
	}
	
	this.updateUserVariable = function (name, value) {
		this.createUserVariable (name, value);
	}
	
	this.sendMessage = function (type, message, var_or_users, variables) {
		var obj2send = new Object ();
		obj2send.what = "msg";
		obj2send.type = type;
		obj2send.message = message;
		obj2send.from = this.sf.myUserName;
		
		var ul = this.sf.getActiveRoom ().getUserList ();
		for (var i in ul) {
			if (ul[i].getId () == this.sf.myUserId) {
				var myObj = ul[i];
				break;
			}
		}		
		
		
		if (type == "public") {
			obj2send.vars = var_or_users;
			this.sf.sendObject (obj2send);
			this.sf.onObjectReceived (obj2send, myObj);
			this.sf.sendPublicMessage (message);
		} else if (type == "private") {
			obj2send.vars = variables;
			var gr = new Array ();
			var ul = this.getUserList ();
			for (var i=0; i<var_or_users.length; i++) {
				for (var j=0; j<ul.length; j++)
					if (var_or_users[i].toString() == ul[j].name.value && var_or_users[i].toString() != myObj.getName ()) {
						gr[gr.length] = ul[j].id;
						break;
					}
			}
			this.sf.sendObjectToGroup (obj2send, gr);
			this.sf.onObjectReceived (obj2send, myObj);
			
			for (var i=0; i<gr.length; i++) {
				this.sf.sendPrivateMessage (msg, gr[i]);
			}
		}
	}
	
	this.sendMove = function (who, obj) {
		var obj2send = new Object ();
		obj2send.what = "move";
		obj2send.obj = obj;
		obj2send.from = this.sf.myUserName;
		
		if (who == "all" || who == "public") {
			obj2send.type = "public";
			this.sf.sendObject (obj2send);
		} else {
			obj2send.type = "private";
			var gr = new Array ();
			var ul = this.getUserList ();
			for (var i=0; i<who.length; i++) {
				for (var j=0; j<ul.length; j++)
					if (who[i] == ul[j].name.value) {
						gr[gr.length] = ul[j].id;
						break;
					}
			}
			this.sf.sendObjectToGroup (obj2send, gr);
		}
	}
	
	this.close = function () {
		this.sf.disconnect ();
	}
		
	this.kick = function (username, reason) {
		var ul = this.sf.getActiveRoom ().getUserList ();
		for (var i in ul) {
			if (ul[i].getName () == username) {
				var userId = ul[i].getId ();
				break;
			}
		}
	
		var dataObj = new Object ();
		dataObj.id = userId.toString();
		dataObj.msg = reason;
		
		//this.sendMessage ("public", "Kicked '" + username + "'! Reason: " + reason);
		this.sf.sendXtMessage ("$dmn", "kick", dataObj);
	}
	
	this.ban = function (username, reason, time) {
		var ul = this.sf.getActiveRoom ().getUserList ();
		for (var i in ul) {
			if (ul[i].getName () == username) {
				var userId = ul[i].getId ();
				break;
			}
		}
	
		var dataObj = new Object ();
		dataObj.id = userId.toString();
		dataObj.msg = reason;
		dataObj.mode = "0"; 
			/*
				0 » ban the user by name
				1 » ban the user by its IP address 
			*/
		//dataObj.time = time;
		
		//this.sendMessage ("public", "Banned '" + username + "'! Reason: " + reason);
		this.sf.sendXtMessage("$dmn", "ban", dataObj);
	}
	
	
	
	
	
	/* EVENTS */
	
	this.sf.onConnection = function (status) {
		this.parent.isConnectedVar = status;
		this.parent.onConnect (status, "Can't connect to the server.");
	}
	
	this.sf.onConnectionLost = function () {
		var ServerInitiated = true;
		this.parent.onClose (ServerInitiated);
	}
	
	this.sf.onLogin = function (success, name, error) {
		this.parent.username = this.myUserName;
		this.parent.loggedIn (success, error);
	}
	
	this.sf.onJoinRoom = function (myRoom) {
		var obj = new Object();
		obj.success = true;
		var roomObj = new Object();
		roomObj.name = new Object();
		roomObj.name.value = myRoom.getName();
		this.parent.createUserVariable ("isMod", this.isModerator());
		this.parent.roomJoined (obj, roomObj);
	}
	
	this.sf.onJoinRoomError = function (errorMsg) {
		var obj = new Object();
		obj.success = false;
		obj.error = errorMsg;
		this.parent.roomJoined (obj);	
	}
	
	this.sf.onUserEnterRoom = function (roomId, userObj) {
		var roomObj = this.parent.getRoomById (roomId);
		var user = userObj.getName ();
		if (roomObj.name.value == this.getActiveRoom ().getName()) {
			this.parent.userListUpdated (this.parent.getUserList (), "userjoined", user);
			break;
		}
	}
	
	this.sf.onUserLeaveRoom = function (roomId, userId, userName) {
		var roomObj = this.parent.getRoomById (roomId);
		if (roomObj.name.value == this.getActiveRoom ().getName()) {
			this.parent.userListUpdated (this.parent.getUserList (), "userleft", userName);
			break;
		}
	}
	
	this.sf.onUserCountChange = function (roomObj) {
		this.parent.zoneUpdated (this.parent.getZone ().numUsers);
		for (var i = 0; i < this.parent.getRoomList ().length; i++)
			if (this.parent.getRoomList ()[i].name.value == roomObj.getName ()) {
				this.parent.roomListUpdated (this.parent.getRoomList (), "roomupdated", this.parent.getRoomList ()[i]);
				break;
			}
	}
	
	this.sf.onUserVariablesUpdate = function (userObj) {
		ul = this.parent.getUserList ();
		for (var i=0; i<ul.length; i++)
			if (ul[i].id == userObj.getId ()) {
				this.parent.userVariableUpdated (ul[i], ul[i].userVariables.lastAction, ul[i].userVariables.lastActionTarget);
				break;
			}
	}
	
	this.sf.onObjectReceived = function (obj, sender) {
		if (obj.what == "msg") {
			this.parent.messageReceived (obj.type, obj.message, obj.from, obj.vars);
		} else if (obj.what == "move") {
			this.parent.moveReceived (obj.type, obj.obj, obj.from);
		} else {
			trace ("*    BUG    *");
		}
	}
	
	this.sf.onRoomListUpdate = function (roomlist) {
		if (this.parent.joinlobby) this.joinRoom ("Lobby");
	}
	
	this.sf.onAdminMessage = function (msg) {
		this.parent.messageReceived ("public", msg, "Administrator");
	}
	
	
	/* PLUGINS */
	
	this.getServerTime = function () {
		this.sf.roundTripBench ();
	}
	
	this.sf.onRoundTripResponse = function (time) {
		this.parent.onGetServerTime (getTimer () + time);
	}
}