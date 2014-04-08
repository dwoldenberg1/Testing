/*
	Actionscript 1.0 Object Serializer / DeSerializer
	version 2.0
	
	Supports:
	--------------------------------------------------
	primitive datatypes: null, boolean, number, string
	object datatypes: object, array
	
	Last update: June 01 2004
*/


ObjectSerializer = function()
{
	this.tabs 	= "\t\t\t\t\t\t\t\t\t\t"			// used for debug only, for xml formatting
	this.xmlStr 	= ""						// the final XML text of the serialized obj
	this.debug 	= false					// if true, formats XML in human readable style
	this.eof	= ""						// end of line constant, used only for debug
	
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
	for (var i = 127; i <= 255; i++)
	{
		this.ascTab[i] = "&#x"+i.toString(16)+";"
		
		this.ascTabRev["&#x"+i.toString(16)+";"] = chr(i);
	}
	
}

ObjectSerializer.prototype.serialize = function(obj)
{
	this.xmlStr 	= ""
	
	if (this.debug) 
		this.eof = "\n"
	
	this.obj2xml(obj, 0, "")					// Call serializer recursive method
	
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
		
		this.xmlStr += "<obj o='" + objn + "'>" + this.eof
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

	this.xml2obj(this.xmlData, this.resObj)			// calls recursive xml parser
	
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
		//if(node.childNodes[i].childNodes.length > 0)
		if (node.childNodes[i].nodeName == "obj")
		{
			// Object Found
			var n = node.childNodes[i].attributes.o
			trace("{ found object = " + node.childNodes[i].attributes.o + "}\n")
			//trace("nodeName: " + node.childNodes[i].nodeName)
		
			currObj[n] = {}
			//trace("node:" + node.childNodes[i])
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
			
			if (fn == String)
				currObj[n] = this.decodeEntities(currObj[n])
		}
		
		// next xml node
  		i++;
	}
}

//---------------------------------------------------------
// Helper functions
// v 0.1
// added on June 01 2004
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
		else if (cod > 126)
		{
			strbuff += this.ascTab[cod]
		}
	}

	return strbuff
}

ObjectSerializer.prototype.decodeEntities = function(st)
{
	var strbuff = ""
	var i = 0
	
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
			
			//trace("found: " + ent)
			
			strbuff += this.ascTabRev[ent]
		}
		else
			strbuff += ch
			
		i++
	}

	return strbuff
}

