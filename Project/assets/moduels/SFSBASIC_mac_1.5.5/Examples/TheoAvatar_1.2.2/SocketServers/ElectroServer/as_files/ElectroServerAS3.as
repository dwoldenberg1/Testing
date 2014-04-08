//ElectroServer Class
//XML Protocol Version 3.2.0
//ActionScript Version 1.0
//Author: Jobe Makar, jobe@electrotank.com
//Company: Electrotank, Inc. http://www.electrotank.com
//
//Last edit: 2/26/2004
//
//-----Revision History---------
//	9/18/03		Officially released
//	10/9/03		Added version detection. If class connects to an older ElectroServer 3 version then an error appears
//	10/11/03	Fixed chat message bug. Messages that were only numberic (e.g. 12345678901234567890) were being parsed as numbers
//	10/20/03	Fixed the way variables are parsed in incoming plugin messages
//	12/21/03	Fixed loginResponse case sensitivity issue (now "accepted" or "Accepted" are valid)	
//	12/23/03	Changed the use of a local var called 'xml' to 'tmp_xml' because of class obsuring
//	12/23/03	Added setDebug(true|false) method. Default is false. If true, inbound and outbound messages are traced
//	12/27/03	GetRoomsInZone("zonename") added. onRoomsInZoneLoaded event added. onRoomsinZoneLoaded(room_list, zone_name)
//	1/19/04		User variable fixes added. Each user object has a UserVariables object contained within, which contains the variables
//	2/24/04		getLoggedInUserCount() added, callback: loggedInUserCountUpdated -- total number of users logged into the server, all zones
//	2/26/04		Modified code for a hidden room work around.
//	5/22/04
//
//!!! Download ElectroServer class updates from here: http://www.electrotank.com/ElectroServer/downloads.asp
//
//=~=+=~=+=~=+=~=+=~=+=~=+=~=+=~=+=~=+=~=+=~=+=~=+=~=+=~=+=~=+=~=+
#include "WDDX_mx.as"
ElectroServerAS = function () {
	// Constructor for ElectroServerAS v3.0 object
	this.MajorVersion = 3;
	this.MinorVersion = 1;
	this.SubVersion = 0;
	this.debug = false;
	_global.ElectroServer = this;
	this.user = new Object();
	this.isConnected = false;
	this.nodeNameList = {Users:true, Zones:true, UserVariables:true, RoomVariables:true, Rooms:true, Variables:true, BannedUsers:true, Plugins:true, Moderators:true, Words:true, RootWords:true, Templates:true};
};
ElectroServerAS.prototype.onFirstConnect = function(success) {
	//hidden
	//The true sign of being able to connect to ElectroServer is that ElectroServer sends
	//an XML packet back to the client. But this event is triggered the socket connection
	//itself is accepted. If success == false then there is a firewall issue or the server is down
	if (!success) {
		var error = "Was not able to connect to the server.";
		this.where.isConnected = false;
		this.where.onConnect(success, error);
	}
};
ElectroServerAS.prototype.assignUserLabel = function(user) {
	if (user.attributes.Moderator) {
		user.icon = "electro";
		if (user.Name.value.toLowerCase() == "jobe") {
			user.icon = "jobe";
		} else if (user.Name.value.toLowerCase() == "mike") {
			user.icon = "";
		} else if (user.Name.value.toLowerCase() == "aloeen") {
			user.icon = "";
		}
		user.iconAlignment = "left";
	}
};
ElectroServerAS.prototype.setDebug = function(val) {
	this.debug = val;
};
ElectroServerAS.prototype.getDebug = function() {
	return this.debug;
};
ElectroServerAS.prototype.ValidateVersion = function(Major, Minor, Sub) {
	var ReturnVal = true;
	if (this.MajorVersion>Major || isNaN(Major)) {
		ReturnVal = false;
	} else if (this.MinorVersion>Minor && this.MajorVersion == Major) {
		ReturnVal = false;
	} else if (this.SubVersion>Sub && this.MinorVersion == Minor) {
		ReturnVal = false;
	}
	return ReturnVal;
};
ElectroServerAS.prototype.pluginRequest = function(plugin, method, parameters) {
	var action = "ExecutePlugin";
	var variableXML = "<Variables />";
	if (parameters != undefined) {
		variableXML = "<Variables>";
		for (var i in parameters) {
			variableXML += "<Variable><Name>"+i+"</Name><Value>"+parameters[i]+"</Value></Variable>";
		}
		variableXML += "</Variables>";
	}
	var parameters = "<Plugin>"+plugin+"</Plugin><Method>"+method+"</Method>"+variableXML;
	this.send(action, parameters);
};
//getLoggedInUserCount
ElectroServerAS.prototype.getLoggedInUserCount = function() {
	var action = "GetLoggedInUserCount";
	var parameters = "";
	this.send(action, parameters);
};
ElectroServerAS.prototype.getServerTime = function() {
	var action = "GetServerTime";
	var parameters = "";
	this.send(action, parameters);
};
ElectroServerAS.prototype.terminateHere = function(xml) {
	//hidden
	//This is used by parseParameters to determine how deep the XML goes
	return xml.childNodes[0].hasChildNodes() ? false : true;
};
ElectroServerAS.prototype.xmlReceived = function(data) {
	//hidden
	//Every packet of XML that is pushed in from the server hits this method forist
	var where = this.where;
	if (where.debug) {
		trace("-----incomming----");
		trace(data);
	}
	var info = data.firstChild.childNodes;
	//Every XML packet has an action
	var action = info[0].firstChild.nodeValue.toLowerCase();
	//Parse the parameters into easy-to-use data objects
	var parameters = info[1].childNodes;
	var params = new Object();
	where.parseParameters(parameters, params, where);
	//Apply the action
	where.applyAction(action, params, where);
};
ElectroServerAS.prototype.isArrayNodeName = function(nodeName, where) {
	//hidden
	//The parseParameters function treats all nodes the same unless they are in
	// the 'nodeNameList', in which case they are converted to arrays
	//This function returns true|false depending on if the nodeName is in the list
	if (where.nodeNameList[nodeName]) {
		return true;
	} else {
		return false;
	}
};
ElectroServerAS.prototype.parseParameters = function(info, parentOb, where) {
	//hidden
	//This is a generic recursive method which walks the parameters node of the message
	//it parses the XML into generic data objects
	//====
	// example:
	// <Parameters><Results>Success</Results></Parameters>
	// parses to  parameters.results which is an object, the value of 'results is:
	// parameters.results.value
	for (var i = 0; i<info.length; ++i) {
		var tmp_xml = info[i];
		var terminate = where.terminateHere(tmp_xml);
		var nodeName = tmp_xml.nodeName;
		if (parentOb instanceof Array) {
			var ob = new Object();
			parentOb.push(ob);
			var ob = parentOb[parentOb.length-1];
		} else {
			parentOb[nodeName] = new Object();
			var ob = parentOb[nodeName];
		}
		for (var j in tmp_xml.attributes) {
			if (ob.attributes == undefined) {
				ob.attributes = new Object();
			}
			var value = tmp_xml.attributes[j];
			if (!isNaN(value)) {
				value = Number(value);
			}
			if (value.toLowerCase() == "true") {
				value = true;
			} else if (value.toLowerCase() == "false") {
				value = false;
			}
			ob.attributes[j] = value;
		}
		if (where.isArrayNodeName(nodeName, where)) {
			ob[nodeName] = new Array();
			var ob = ob[nodeName];
		}
		if (terminate) {
			// No further sub-nodes
			var nodeValue = tmp_xml.firstChild.nodeValue;
			if (!isNaN(nodeValue, where) && nodeValue != undefined && tmp_xml.nodeName != "Message") {
				nodeValue = Number(nodeValue);
			}
			ob.value = nodeValue;
		} else {
			// There are sub-nodes that need parsing
			var nodeName = tmp_xml.nodeName;
			var children = tmp_xml.childNodes;
			where.parseParameters(children, ob, where, arrOb);
		}
	}
};
ElectroServerAS.prototype.login = function(username, password) {
	this.user.username = username;
	if (password == undefined) {
		password = "";
	}
	this.user.password = password;
	this.username = this.user.username;
	this.password = this.user.password;
	var action = "Login";
	//var parameters = "<Name>"+this.user.username+"</Name><Password>"+this.user.password+"</Password><UserVariables><UserVariable><Name>ssss</Name><Data><![CDATA[ffff]]></Data></UserVariable></UserVariables>";
	var parameters = "<Name>"+this.user.username+"</Name><Password>"+this.user.password+"</Password><UserVariables/>";
	this.send(action, parameters);
};
ElectroServerAS.prototype.loadConfiguration = function() {
	var action = "LoadConfiguration";
	var parameters = "";
	this.send(action, parameters);
};
ElectroServerAS.prototype.adminLogin = function(username, password) {
	this.user.username = username;
	if (password == undefined) {
		password = "";
	}
	this.user.password = password;
	this.username = this.user.username;
	this.password = this.user.password;
	var action = "AdminLogin";
	var parameters = "<Name>"+this.user.username+"</Name><Password>"+this.user.password+"</Password>";
	this.send(action, parameters);
};
ElectroServerAS.prototype.deleteRoomVariable = function(name) {
	var action = "DeleteRoomVariable";
	var parameters = "<RoomVariable ><Name>"+name+"</Name></RoomVariable>";
	this.send(action, parameters);
};
ElectroServerAS.prototype.changeRoomDetail = function(detail, value) {
	var action = "ChangeRoomDetails";
	var minorAction;
	var field;
	var detail = detail.toLowerCase();
	var pwordXML = "";
	if (detail == "description") {
		minorAction = "ChangeDescription";
		field = "Description";
		value.attributes.isGameRoom = true;
		var wddxOb = new WDDX();
		var descXML = "<![CDATA["+wddxOb.serialize(value)+"]]>";
	} else if (detail == "updatable") {
		minorAction = "ChangeUpdatable";
		field = "Updatable";
		var descXML = value;
	} else if (detail == "hidden") {
		minorAction = "ChangeVisibility";
		field = "Hidden";
		var descXML = value;
	} else if (detail == "capacity") {
		minorAction = "ChangeCapacity";
		filed = "Capacity";
		if (value == undefined || value == 0) {
			value = -1;
		}
		var descXML = value;
	} else if (detail == "password") {
		minorAction = "ChangePasswordProtected";
		field = "Password";
		var descXML = value;
		if (value == undefined) {
			value = "";
		}
		if (value.length>=1) {
			var protected = true;
		} else {
			var protected = false;
		}
		pwordXML = "<IsProtected>"+protected+"</IsProtected>";
	}
	var parameters = "<MinorAction>"+minorAction+"</MinorAction>"+pwordXML+"<"+field+">"+descXML+"</"+field+">";
	this.send(action, parameters);
};
ElectroServerAS.prototype.kick = function(name, reason) {
	if (reason == undefined) {
		reason = "";
	}
	var action = "ModeratorCommand";
	var parameters = "<MinorAction>Kick</MinorAction><UserName>"+name+"</UserName><Reason>"+reason+"</Reason>";
	this.send(action, parameters);
};
ElectroServerAS.prototype.ban = function(name, reason, expires) {
	if (reason == undefined) {
		reason = "";
	}
	if (expires == undefined) {
		expires = "-1";
	}
	var action = "ModeratorCommand";
	var parameters = "<MinorAction>Ban</MinorAction><UserName>"+name+"</UserName><Reason>"+reason+"</Reason><Expires>"+expires+"</Expires>";
	this.send(action, parameters);
};
ElectroServerAS.prototype.updateUserVariable = function(name, value) {
	var action = "UpdateUserVariable";
	var parameters = "<MinorAction>Update</MinorAction><Name>"+name+"</Name><Data>"+value+"</Data>";
	this.send(action, parameters);
};
ElectroServerAS.prototype.deleteUserVariable = function(name) {
	var action = "DeleteUserVariable";
	var parameters = "<UserVariable><Name>"+name+"</Name></UserVariable>";
	this.send(action, parameters);
};
ElectroServerAS.prototype.createUserVariable = function(name, value) {
	var action = "UpdateUserVariable";
	var parameters = "<MinorAction>Create</MinorAction><Name>"+name+"</Name><Data>"+value+"</Data>";
	this.send(action, parameters);
};
ElectroServerAS.prototype.createRoomVariable = function(ob) {
	var name = ob.name;
	var data = ob.data;
	var persistent = ob.persistent;
	var locked = ob.locked;
	if (persistent == undefined) {
		persistent = false;
	}
	if (locked == undefined) {
		locked = false;
	}
	if (this.zone.myRoom.roomVariables[name] == undefined) {
		var action = "CreateRoomVariable";
		var parameters = "<RoomVariable Persistent=\""+persistent+"\" Locked=\""+locked+"\" ><Name>"+name+"</Name><Data><![CDATA["+data+"]]></Data></RoomVariable>";
	} else {
		var action = "UpdateRoomVariable";
		var parameters = "<RoomVariable Locked=\""+locked+"\" ><Name>"+name+"</Name><Data><![CDATA["+data+"]]></Data></RoomVariable>";
	}
	this.send(action, parameters);
};
ElectroServerAS.prototype.send = function(action, parameters) {
	//hidden
	var message = "<XmlDoc><Action>"+action+"</Action><Parameters>"+parameters+"</Parameters></XmlDoc>";
	if (this.debug) {
		trace("---out going----");
		trace(message);
	}
	this.server.send(message);
};
ElectroServerAS.prototype.close = function() {
	this.server.close();
	this.onClose(false);
};
ElectroServerAS.prototype.serverClosedConnection = function() {
	this.where.onClose(true);
};
ElectroServerAS.prototype.connect = function(ip, port) {
	if (ip != undefined) {
		this.setIP(ip);
	}
	if (port != undefined) {
		this.setPort(port);
	}
	this.connected = false;
	this.server = new XMLSocket();
	this.server.where = this;
	this.server.onConnect = this.onFirstConnect;
	this.server.onXML = this.xmlReceived;
	this.server.onClose = this.serverClosedConnection;
	this.server.connect(this.ip, this.port);
};
ElectroServerAS.prototype.setIP = function(ip) {
	this.ip = ip;
};
ElectroServerAS.prototype.getIP = function() {
	return this.ip;
};
ElectroServerAS.prototype.setPort = function(port) {
	this.port = port;
};
ElectroServerAS.prototype.getPort = function() {
	return this.port;
};
ElectroServerAS.prototype.getZone = function() {
	return this.zone;
};
ElectroServerAS.prototype.joinGame = function(room, password, type, zone) {
	var type = type.toLowerCase();
	if (type == "player" || type == undefined) {
		var numbered = true;
	} else if (type == "spectator") {
		var numbered = false;
	}
	this.joinRoom(room, password, zone, numbered);
	this.inGame = true;
};
ElectroServerAS.prototype.joinRoom = function(room, password, zone, numbered) {
	var action = "JoinRoom";
	if (numbered == undefined) {
		numbered = true;
	}
	if (password == undefined) {
		password = "";
	}
	if (zone == undefined) {
		zone = this.zone.name;
	}
	this.pendingRoom = room;
	this.inGame = false;
	this.creatingRoom = false;
	var parameters = "<Zone><Name>"+zone+"</Name><Room><Name>"+room+"</Name><Password>"+password+"</Password><Numbered>"+numbered+"</Numbered></Room></Zone>";
	this.send(action, parameters);
};
ElectroServerAS.prototype.sendMessage = function(type, message, users, variables) {
	var type = type.toLowerCase();
	if (type == "public" || type == "all") {
		//'users' is actually the variables for public messages
		this.sendPublicMessage(message, users);
	} else if (type == "private") {
		this.sendPrivateMessage(message, users, variables);
	}
};
ElectroServerAS.prototype.sendPublicMessage = function(message, variables) {
	var action = "SendPublicMessage";
	//var parameters = "<Message><![CDATA["+message+"]]></Message><Variables><Variable><Name>Test Var</Name><Data>Yaya</Data></Variables>";
	var variableXML = "";
	for (var i in variables) {
		var name = i;
		var value = variables[i];
		variableXML += "<Variable><Name>"+name+"</Name><Data><![CDATA["+value+"]]></Data></Variable>";
	}
	if (variableXML != "") {
		variableXML = "<Variables>"+variableXML+"</Variables>";
	} else {
		variableXML = "<Variables />";
	}
	var parameters = "<Message><![CDATA["+message+"]]></Message>"+variableXML;
	this.send(action, parameters);
};
ElectroServerAS.prototype.sendPrivateMessage = function(message, users, variables) {
	var action = "SendPrivateMessage";
	var usersXML = "<Users>";
	for (var i = 0; i<users.length; ++i) {
		var user = users[i];
		usersXML += "<User>"+user+"</User>";
	}
	usersXML += "</Users>";
	var variableXML = "";
	for (var i in variables) {
		var name = i;
		var value = variables[i];
		variableXML += "<Variable><Name>"+name+"</Name><Data><![CDATA["+value+"]]></Data></Variable>";
	}
	if (variableXML != "") {
		variableXML = "<Variables>"+variableXML+"</Variables>";
	} else {
		variableXML = "<Variables />";
	}
	var parameters = usersXML+"<Message><![CDATA["+message+"]]></Message>"+variableXML;
	this.send(action, parameters);
};
ElectroServerAS.prototype.cancelChallenge = function() {
	this.challenging = false;
	delete this.opponent;
	var ob = new Object();
	ob.action = "challengecancelled";
	this.sendMove(who, ob);
};
ElectroServerAS.prototype.sendChallenge = function(who, game) {
	var ob = new Object();
	ob.action = "challenge";
	ob.game = game;
	this.challenging = true;
	this.opponent = who;
	this.sendMove(who, ob);
};
ElectroServerAS.prototype.sendAutoDecline = function(who) {
	var ob = new Object();
	ob.action = "autodecline";
	this.sendMove(who, ob);
};
ElectroServerAS.prototype.sendDecline = function(who) {
	var ob = new Object();
	ob.action = "decline";
	this.sendMove(who, ob);
};
ElectroServerAS.prototype.sendMove = function(who, ob) {
	var wddxOb = new WDDX();
	var moveXML = wddxOb.serialize(ob);
	if (who.toLowerCase() == "all") {
		var action = "SendPublicMessage";
		//var parameters = "<Message><![CDATA["+message+"]]></Message><Variables><Variable><Name>Test Var</Name><Data>Yaya</Data></Variables>";
		var parameters = "<Message><![CDATA["+moveXML+"]]></Message><Variables><Variable><Name>Action</Name><Data>Move</Data></Variable><Variable><Name>MoveType</Name><Data>Public</Data></Variable></Variables>";
	} else {
		var action = "SendPrivateMessage";
		var users = who;
		var usersXML = "<Users>";
		for (var i = 0; i<users.length; ++i) {
			var user = users[i];
			usersXML += "<User>"+user+"</User>";
		}
		usersXML += "</Users>";
		var parameters = usersXML+"<Message><![CDATA["+moveXML+"]]></Message><Variables><Variable><Name>Action</Name><Data>Move</Data></Variable><Variable><Name>MoveType</Name><Data>Public</Data></Variable></Variables>";
	}
	this.send(action, parameters);
};
ElectroServerAS.prototype.getRoomList = function() {
	return this.zone.rooms;
};
ElectroServerAS.prototype.getRoom = function() {
	return this.zone.myRoom;
};
ElectroServerAS.prototype.getUserList = function() {
	return this.zone.users;
};
ElectroServerAS.prototype.createGameRoom = function(roomOb) {
	if (roomOb.attributes == undefined) {
		roomOb.attributes = new Object();
	}
	roomOb.attributes.isGameRoom = true;
	roomOb.updatable = false;
	roomOb.numbered = true;
	this.createRoom(roomOb);
	this.inGame = true;
};
ElectroServerAS.prototype.createRoom = function(roomOb, auto_join) {
	//roomOb properties: zone, roomName, hidden, numbered, UserVariablesEnabled, Description
	//Password, Capacity, roomVariables
	if (auto_join == undefined || auto_join == "true") {
		auto_join = true;
	} else {
		auto_join = false;
	}
	this.auto_join = auto_join;
	var action = "CreateRoom";
	var password = roomOb.password;
	var UserVariablesEnabled = roomOb.userVariablesEnabled;
	var hidden = roomOb.hidden;
	var zone = roomOb.zone;
	var roomName = roomOb.roomName;
	var numbered = roomOb.numbered;
	var capacity = roomOb.capacity;
	var description = roomOb.description;
	var roomVariables = roomOb.roomVariables;
	var updatable = roomOb.updatable;
	var plugins = roomOb.plugins;
	var descOb = new Object();
	var FloodingFilterEnabled = roomOb.FloodingFilterEnabled;
	descOb.description = description;
	if (roomOb.attributes != undefined) {
		descOb.attributes = roomOb.attributes;
	}
	var wddxOb = new WDDX();
	var descXML = wddxOb.serialize(descOb);
	if (zone == undefined) {
		zone = this.zone.name;
	}
	if (FloodingFilterEnabled == undefined) {
		FloodingFilterEnabled = true;
	}
	if (updatable == undefined) {
		updatable = true;
	}
	if (hidden == undefined) {
		hidden = false;
	}
	if (capacity == undefined) {
		capacity = -1;
	}
	if (numbered == undefined) {
		numbered = false;
	}
	if (description == undefined) {
		description = "";
	}
	if (password == undefined) {
		password = "";
	}
	if (UserVariablesEnabled == undefined) {
		UserVariablesEnabled = false;
	}
	if (roomVariables == undefined) {
		var roomVariableXML = "<RoomVariables/>";
	} else {
		var roomVariableXML = "<RoomVariables>";
		for (var i = 0; i<roomVariables.length; ++i) {
			var ob = roomVariables[i];
			var persistent = ob.persistent;
			var locked = ob.locked;
			var name = ob.name;
			var data = ob.data;
			if (persistent == undefined) {
				persistent = false;
			}
			if (locked == undefined) {
				locked = false;
			}
			var str = "<RoomVariable Persistent=\""+persistent+"\" Locked=\""+locked+"\">";
			str += "<Name>"+name+"</Name>";
			str += "<Data><![CDATA["+data+"]]></Data>";
			str += "</RoomVariable>";
			roomVariableXML += str;
		}
		roomVariableXML += "</RoomVariables>";
	}
	if (plugins == undefined) {
		var pluginXML = "<Plugins />";
	} else {
		var pluginXML = "<Plugins>";
		for (var i = 0; i<plugins.length; ++i) {
			var plugin = plugins[i];
			var name = plugin.name;
			var pluginVariables = plugin.variables;
			if (pluginVariables == undefined) {
				var pluginVariablesXML = "<Variables />";
			} else {
				var pluginVariablesXML = "<Variables>";
				for (var j in pluginVariables) {
					var pluginVarValue = pluginVariables[j];
					pluginVariablesXML += "<Variable><Name>"+j+"</Name><Value>"+pluginVarValue+"</Value></Variable>";
				}
				pluginVariablesXML += "</Variables>";
			}
			pluginXML += "<Plugin><Name>"+name+"</Name>"+pluginVariablesXML+"</Plugin>";
		}
		pluginXML += "</Plugins>";
	}
	var parameters = "<Zone><Name>"+zone+"</Name><Room Updatable=\""+updatable+"\" Hidden=\""+hidden+"\" Numbered=\""+Numbered+"\" FloodingFilterEnabled=\""+FloodingFilterEnabled+"\" UserVariablesEnabled=\""+UserVariablesEnabled+"\"><Name>"+roomName+"</Name><Password>"+password+"</Password><Description><![CDATA["+descXML+"]]></Description><Capacity>"+capacity+"</Capacity>"+roomVariableXML+pluginXML+"</Room></Zone>";
	this.joiningRoom = true;
	this.pendingRoom = roomName;
	this.pendingZone = zone;
	this.creatingRoom = true;
	this.inGame = false;
	this.send(action, parameters);
};
ElectroServerAS.prototype.getRoomsInZone = function(tmp_zone) {
	this.send("GetRoomsInZone", "<Zone>"+tmp_zone+"</Zone>");
};
ElectroServerAS.prototype.getUser = function() {
	return this.myUser;
};
ElectroServerAS.prototype.getRoomVariables = function() {
	return this.zone.myRoom.roomVariables;
};
ElectroServerAS.prototype.parseConfig = function(config, where) {
	XML.prototype.ignoreWhite = true;
	var temp = new XML(config);
	var params = new Object();
	where.parseParameters(temp.firstChild.childNodes, params, where);
	where.configurationLoaded(params);
};
ElectroServerAS.prototype.applyAction = function(action, params, where) {
	if (action == "connectionresponse") {
		//This is a willful response from the server
		var Major = Number(params.Version.attributes.Major);
		var Minor = Number(params.Version.attributes.Minor);
		var Sub = Number(params.Version.attributes.Sub);
		if (params.result.value == "Accepted" && where.ValidateVersion(Major, Minor, Sub)) {
			//properly connected
			where.connected = true;
			where.onConnect(true);
			where.isConnected = true;
		} else {
			if (params.result.value == "Accepted" && !where.ValidateVersion(Major, Minor, Sub)) {
				//version is too old
				var error = "ElectroServer 3 version is too old. Please install latest.";
				trace("=====================================================");
				trace("===============Error Error Error=====================");
				trace("This class file is newer than the version of ElectroServer 3 that you are using.");
				trace("AS 2.0 Class version: "+where.MajorVersion+"."+where.MinorVersion+"."+where.SubVersion);
				trace("ElectroServer version: "+Major+"."+Minor+"."+Sub);
				trace("If it says NaN above, then you definately need to update.");
				trace("Visit http://www.electrotank.com/ElectroServer/");
				trace("=====================================================");
				trace("=====================================================");
			} else {
				//did not connect properly
				var error = params.reason.value;
			}
			trace("Connection failure!!!!!!!!!!!!!!!!!!!!!!!!");
			where.isConnected = false;
			where.onConnect(false, error);
		}
	} else if (action == "loginresponse") {
		if (params.result.value.toLowerCase() == "accepted") {
			var variables_array = params.Variables.Variables;
			where.loggedin(true, undefined, variables_array);
		} else {
			var error = params.reason.value;
			where.loggedin(false, error);
		}
	} else if (action == "createroom") {
		if (params.result.value != "Success") {
			var error = params.Reason.value;
			if (where.auto_join) {
				where.joinRoom(where.pendingRoom, "", where.pendingZone);
			} else {
				where.roomCreated(false, error);
			}
		}
	} else if (action == "loadconfiguration") {
		var num_packets = params.numberOfPackets.value;
		var num = params.packetNumber.value;
		var packetData = params.packetData.value;
		if (num == "1") {
			where.configXML = packetData;
		} else {
			where.configXML += packetData;
		}
		if (num == num_packets) {
			where.parseConfig(where.configXML, where);
		}
	} else if (action == "joinroom") {
		if (params.result.value == "Success") {
			//joined the room successfully
			var roomName = where.pendingRoom;
			var roomList = where.zone.rooms;
			for (var i = 0; i<roomList.length; ++i) {
				var roomOb = roomList[i];
				if (roomOb.name.value == roomName) {
					where.zone.myRoom = roomOb;
					var rv = params.roomVariables.roomVariables;
					where.zone.myRoom.roomVariables = new Object();
					for (var j = 0; j<rv.length; ++j) {
						var name = rv[j].name.value;
						var value = rv[j].data.value;
						where.zone.myRoom.roomVariables[name] = value;
					}
					where.roomVariablesUpdated("all", where.zone.myRoom.roomVariables);
					break;
				}
			}
			if (where.creatingRoom) {
				where.roomCreated(true);
				where.creatingRoom = false;
			}
			where.roomJoined({success:true}, where.zone.myRoom);
			delete where.pendingRoom;
			where.joiningRoom = false;
			//deal with userlist
			where.zone.users = params.users.users;
			for (var i = 0; i<where.zone.users.length; ++i) {
				var user = where.zone.users[i];
				var user_name = user.Name.value;
				user.label = user_name;
				where.assignUserLabel(user);
				var uv = user.UserVariables.UserVariables;
				user.userVariables = new Object();
				for (var k = 0; k<uv.length; ++k) {
					var u = uv[k];
					var user_var_name = u.Name.value;
					var user_var_val = u.Data.value;
					user.userVariables[user_var_name] = user_var_val;
				}
				if (user_name == where.username) {
					where.myUser = user;
					if (user.assignedNumber.value == 0) {
						user.isGameMaster = true;
					}
					break;
				}
			}
			where.userListUpdated(where.zone.users, "all");
		} else {
			//Failed to join the room
			var error = params.reason.value;
			where.roomJoined({success:false, error:error});
		}
	} else if (action == "renumberusers") {
		var users = where.zone.users;
		for (var i = 0; i<params.users.users.length; ++i) {
			var username = params.users.users[i].name.value;
			for (var j = 0; j<users.length; ++j) {
				if (username == users[j].name.value) {
					users[j].AssignedNumber.value = params.users.users[i].AssignedNumber.value;
					users[j].isGameMaster = false;
				}
			}
			if (where.getUser().assignedNumber.value == 0) {
				where.getUser().isGameMaster = true;
			}
		}
		if (where.myUser.assignednumber.value == 0) {
			where.isGameMaster = true;
		} else {
			where.isGameMaster = false;
		}
		where.usersRenumbered(users);
	} else if (action == "sendprivatemessage") {
		var message = params.message.value;
		var from = params.user.value;
		var variables = new Object();
		for (var i = 0; i<params.variables.variables.length; ++i) {
			var name = params.variables.variables[i].name.value;
			var value = params.variables.variables[i].data.value;
			variables[name] = value;
		}
		if (variables.action.toLowerCase() == "move") {
			var what = message;
			var foo = new WDDX();
			var ob = foo.deserialize(what);
			if (ob.action == "challenge") {
				var game = ob.game;
				if (where.challenging || where.inGame || where.respondingToChallenge) {
					where.sendAutoDecline(from, game);
				} else {
					where.opponent = from;
					where.respondingToChallenge = true;
					where.challengeReceived(from, game);
				}
			} else if (ob.action == "autodecline") {
				where.challenging = false;
				delete where.opponent;
				where.challengeDeclined(true);
			} else if (ob.action == "decline") {
				where.challenging = false;
				delete where.opponent;
				where.challengeDeclined(false);
			} else if (ob.action == "challengecancelled") {
				where.respondingToChallenge = false;
				delete where.opponent;
				where.challengeCancelled();
			} else if (ob.action == "challengeaccepted") {
				where.respondingToChallenge = false;
				where.challengeAccepted();
			} else {
				where.moveReceived("private", ob, from);
			}
		} else {
			where.messageReceived("private", message, from, variables);
		}
	} else if (action == "sendpublicmessage") {
		var message = params.message.value;
		var from = params.user.value;
		var variables = new Object();
		for (var i = 0; i<params.variables.variables.length; ++i) {
			var name = params.variables.variables[i].name.value;
			var value = params.variables.variables[i].data.value;
			variables[name] = value;
		}
		if (variables.action.toLowerCase() == "move") {
			var what = message;
			var foo = new WDDX();
			var ob = foo.deserialize(what);
			where.moveReceived("public", ob, from);
		} else {
			where.messageReceived("public", message, from, variables);
		}
	} else if (action == "getroomsinzone") {
		//where.zone = new Object();
		var zone = where.zone;
		//zone.numUsers = Number(params.zone.attributes.users);
		//zone.name = params.zone.name.value;
		//zone.rooms = params.zone.rooms.rooms;
		var tmp_rooms = params.zone.rooms.rooms;
		var show_nums = true;
		for (var i = 0; i<tmp_rooms.length; ++i) {
			var room_name = tmp_rooms[i].Name.value;
			var label = "";
			if (show_nums) {
				label = room_name+" ("+tmp_rooms[i].attributes.Users+")";
			} else {
				label = room_name;
			}
			tmp_rooms[i].label = label;
			tmp_rooms[i].iconAlignment = "left";
			var WDDXxml = tmp_rooms[i].description.value;
			if (WDDXxml.length>2) {
				var foo = new WDDX();
				var ob = foo.deserialize(WDDXxml);
			} else {
				var ob = new Object();
			}
			tmp_rooms[i].description = ob;
		}
		where.onRoomsInZoneLoaded(tmp_rooms, params.zone.name.value);
	} else if (action == "roomlist") {
		var myOldRoom = where.zone.myRoom;
		var oldUsers = where.zone.users;
		where.zone = new Object();
		where.zone.users = oldUsers;
		var zone = where.zone;
		zone.numUsers = Number(params.zone.attributes.users);
		zone.name = params.zone.name.value;
		zone.rooms = params.zone.rooms.rooms;
		for (var i = 0; i<zone.rooms.length; ++i) {
			var room_name = zone.rooms[i].Name.value;
			zone.rooms[i].label = room_name;
			zone.rooms[i].iconAlignment = "left";
			var WDDXxml = zone.rooms[i].description.value;
			if (WDDXxml.length>2) {
				var foo = new WDDX();
				var ob = foo.deserialize(WDDXxml);
			} else {
				var ob = new Object();
			}
			zone.rooms[i].description = ob;
			if (room_name == myOldRoom.Name.value) {
				zone.myRoom = myOldRoom;
				zone.rooms[i] = myOldRoom;
			}
		}
		where.zoneChanged(zone.name);
		where.roomListUpdated(where.zone.rooms, "all");
	} else if (action == "updateuserlist") {
		var minorAction = params.minorAction.value.toLowerCase();
		if (minorAction == "userjoined") {
			var users = where.zone.users;
			var user = params.user;
			user.label = user.Name.value;
			//
				var user_name = user.Name.value;
				var uv = user.UserVariables.UserVariables;
				user.userVariables = new Object();
				for (var k = 0; k<uv.length; ++k) {
					var u = uv[k];
					var user_var_name = u.Name.value;
					var user_var_val = u.Data.value;
					user.userVariables[user_var_name] = user_var_val;
				}

			//
			where.assignUserLabel(user);
			users.push(user);
			where.userListUpdated(where.zone.users, "userjoined", user.name.value);
		} else if (minorAction == "userleft") {
			var users = where.zone.users;
			var user = params.user;
			var username = user.name.value;
			if (username == where.opponent) {
				where.challenging = false;
				delete where.opponent;
				where.challengeDeclined(true);
			}
			for (var i = 0; i<users.length; ++i) {
				var name = users[i].name.value;
				if (username == name) {
					users.splice(i, 1);
					break;
				}
			}
			where.userListUpdated(where.zone.users, "userleft", user.name.value);
		}
	} else if (action == "updateuservariable") {
		var users = where.zone.users;
		var ob = params.UserVariable;
		var tmp_user = ob.User.value;
		var value = ob.Data.value;
		var name = ob.Name.value;
		for (var i = 0; i<users.length; ++i) {
			var tmp = users[i].Name.value;
			if (tmp_user == tmp) {
				var user = users[i];
				var type = typeof user.userVariables[name];
				if (type.toString() == "undefined") {
					user.userVariables[name] = value;
					where.userVariableUpdated(user, "created", name);
				} else {
					user.userVariables[name] = value;
					where.userVariableUpdated(user, "updated", name);
				}
				break;
			}
		}
	} else if (action == "deleteuservariable") {
		var users = where.zone.users;
		var ob = params.UserVariable;
		var tmp_user = ob.User.value;
		var name = ob.Name.value;
		for (var i = 0; i<users.length; ++i) {
			var tmp = users[i].Name.value;
			if (tmp_user == tmp) {
				var user = users[i];
				delete user[name];
				where.userVariableUpdated(user, "deleted", name);
				break;
			}
		}
	} else if (action == "sendpluginmessage") {
		var plugin = params.user.value;
		var pluginAction = params.message.value;
		var variables = params.variables.variables;
		var ob = new Object();
		for (var i = 0; i<variables.length; ++i) {
			var name = variables[i].Name.value;
			var value = variables[i].Value.value;
			ob[name] = value;
		}
		where.pluginMessageReceived(plugin, pluginAction, ob);
	} else if (action == "updateroomvariable") {
		var minorAction = params.minorAction.value.toLowerCase();
		if (minorAction == "create") {
			var name = params.roomVariable.name.value;
			var value = params.roomVariable.data.value;
			where.zone.myRoom.roomVariables[name] = value;
			where.roomVariablesUpdated("created", where.zone.myRoom.roomVariables, name);
		} else if (minorAction == "update") {
			var name = params.roomVariable.name.value;
			var value = params.roomVariable.data.value;
			where.zone.myRoom.roomVariables[name] = value;
			where.roomVariablesUpdated("updated", where.zone.myRoom.roomVariables, name);
		} else if (minorAction == "delete") {
			var name = params.roomVariable.name.value;
			delete where.zone.myRoom.roomVariables[name];
			where.roomVariablesUpdated("deleted", where.zone.myRoom.roomVariables, name);
		}
	} else if (action == "getloggedinusercount") {
		where.loggedInUserCountUpdated(params.LoggedInUsers.value);
	} else if (action == "getservertime") {
		where.onGetServerTime(params.ServerTime.value);
	} else if (action == "updateroomlist") {
		var minorAction = params.minorAction.value.toLowerCase();
		var zone = where.zone;
		zone.numUsers = Number(params.zone.attributes.users);
		where.zoneUpdated(zone.numUsers);
		var newRoomOb = params.zone.rooms.rooms[0];
		if (minorAction == "changeroomdetails") {
			//Room that already exists was changed
			for (var j = 0; j<where.zone.rooms.length; ++j) {
				var roomOb = where.zone.rooms[j];
				var room_name = newRoomOb.name.value;
				if (roomOb.name.value == room_name) {
					for (var i in newRoomOb) {
						roomOb[i] = newRoomOb[i];
					}
					roomOb.label = room_name;
					roomOb.iconAlignment = "left";
					var WDDXxml = newRoomOb.description.value;
					if (wddxXML.length>2) {
						var foo = new WDDX();
						var ob = foo.deserialize(WDDXxml);
					} else {
						var ob = new Object();
					}
					roomOb.description = ob;
					break;
				}
			}
			where.roomListUpdated(where.zone.rooms, "roomupdated", roomOb);
		} else if (minorAction == "createroom") {
			//Add a new room to the room list
			var roomOb = newRoomOb;
			roomOb.label = roomOb.Name.value;
			roomOb.iconAlignment = "left";
			var WDDXxml = roomOb.description.value;
			var foo = new WDDX();
			var ob = foo.deserialize(WDDXxml);
			roomOb.description = ob;
			where.zone.rooms.push(roomOb);
			where.roomListUpdated(where.zone.rooms, "roomcreated", roomOb);
		} else if (minorAction == "deleteroom") {
			//Room that already exists was deleted
			for (var j = 0; j<where.zone.rooms.length; ++j) {
				var roomOb = where.zone.rooms[j];
				if (roomOb.name.value == newRoomOb.name.value) {
					var deleteIt = true;
					if (roomOb.Name.value == where.zone.myRoom.Name.value && !where.joiningRoom) {
						deleteIt = false;
					}
					if (deleteIt) {
						var name = newRoomOb.name.value;
						where.zone.rooms.splice(j, 1);
					}
					break;
				}
			}
			where.roomListUpdated(where.zone.rooms, "roomdeleted", name);
		}
	}
};
//=~=+=~=+=~=+=~=+=~=+=~=+=~=+=~=+=~=+=~=+=~=+=~=+=~=+=~=+=~=+=~=+
