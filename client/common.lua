AddEventHandler('rdx:getSharedObject', function(cb)
	cb(RDX)
end)

exports("getSharedObject", function()
	return RDX
end)
