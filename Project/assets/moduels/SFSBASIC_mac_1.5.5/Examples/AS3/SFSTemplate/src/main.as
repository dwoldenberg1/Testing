/**
 *	SmartFoxClient Actionscript 3.0 code template
 *	version 1.0.0
 * 
 * (c) 2004-2007 gotoAndPlay()
 * www.smartfoxserver.com
 * www.gotoandplay.it 
*/
import it.gotoandplay.smartfoxserver.SmartFoxClient;
import it.gotoandplay.smartfoxserver.SFSEvent;
import flash.events.Event;

private const NEWLINE:String = "\n";
private var sfs:SmartFoxClient;

public function main():void
{
	sfs = new SmartFoxClient(true);
	
	// Register for SFS events
	sfs.addEventListener(SFSEvent.onConnection, onConnection);
	sfs.addEventListener(SFSEvent.onConnectionLost, onConnectionLost);
	sfs.addEventListener(SFSEvent.onLogin, onLogin);
	sfs.addEventListener(SFSEvent.onRoomListUpdate, onRoomListUpdate);
	sfs.addEventListener(SFSEvent.onJoinRoom, onJoinRoom);
	sfs.addEventListener(SFSEvent.onJoinRoomError, onJoinRoomError);
	
	// Register for generic errors
	sfs.addEventListener(SecurityErrorEvent.SECURITY_ERROR, onSecurityError)
	sfs.addEventListener(IOErrorEvent.IO_ERROR, onIOError)
	
	debugTrace("Click the CONNECT button to start");
}

/**
 * Handles the button click
 * Establishes a connection to the local server (127.0.0.1), default TCP port (9339)
 */
public function bt_connect_click(evt:Event):void
{
	if (!sfs.isConnected)
		sfs.connect("127.0.0.1");
	else
		debugTrace("You are already connected!");
}

/**
 * Handle connection
 */
public function onConnection(evt:SFSEvent):void
{
	var success:Boolean = evt.params.success;
	
	if (success)
	{
		debugTrace("Connection successfull!");
		// Attempt to log in "simpleChat" Zone as a guest user
		sfs.login("simpleChat", "", "");
	}
	else
	{
		debugTrace("Connection failed!");	
	}
}

/**
 * Handle connection lost
 */
public function onConnectionLost(evt:SFSEvent):void
{
	debugTrace("Connection lost!");
}

/**
 * Handle login response
 */
public function onLogin(evt:SFSEvent):void
{
	if (evt.params.success)
	{
		debugTrace("Successfully logged in");
	}
	else
	{
		debugTrace("Login failed. Reason: " + evt.params.error);
	}
}

/**
 * Handle room list
 */
public function onRoomListUpdate(evt:SFSEvent):void
{
	debugTrace("Room list received");
	
	// Tell the server to auto-join us in the default room for this Zone
	sfs.autoJoin();
}

/**
 * Handle successfull join
 */
public function onJoinRoom(evt:SFSEvent):void
{
	debugTrace("Successfully joined room: " + evt.params.room.getName());
}

/**
 * Handle problems with join
 */
public function onJoinRoomError(evt:SFSEvent):void
{
	debugTrace("Problems joining default room. Reason: " + evt.params.error);	
}

/**
 * Handle a Security Error
 */
public function onSecurityError(evt:SecurityErrorEvent):void
{
	debugTrace("Security error: " + evt.text);
}

/**
 * Handle an I/O Error
 */
public function onIOError(evt:IOErrorEvent):void
{
	debugTrace("I/O Error: " + evt.text);
}

/**
 * Trace messages to the debug text area
 */
public function debugTrace(msg:String):void
{
	ta_debug.text += "--> " + msg + NEWLINE;
}
