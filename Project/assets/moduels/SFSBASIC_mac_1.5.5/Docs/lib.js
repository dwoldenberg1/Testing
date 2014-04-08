// Check if we're online or locally
if (location.href.indexOf("http://") > -1)
{
	// Invoke the framer
	if (parent.frames.length == 0)
		location.href = "/docs/index.htm?" + location.href
}