function RDX.Streaming.RequestModel(model, cb)
	if not HasModelLoaded(model) and IsModelInCdimage(model) then
		RequestModel(model)
		while not HasModelLoaded(model) do
			Wait(0)
		end
	end

	if cb ~= nil then
		cb()
	end
end

function RDX.Streaming.RequestStreamedTextureDict(textureDict, cb)
	if not HasStreamedTextureDictLoaded(textureDict) then
		RequestStreamedTextureDict(textureDict)
		while not HasStreamedTextureDictLoaded(textureDict) do
			Wait(0)
		end
	end

	if cb ~= nil then
		cb()
	end
end

function RDX.Streaming.RequestNamedPtfxAsset(assetName, cb)
	if not HasNamedPtfxAssetLoaded(assetName) then
		RequestNamedPtfxAsset(assetName)
		while not HasNamedPtfxAssetLoaded(assetName) do
			Wait(0)
		end
	end

	if cb ~= nil then
		cb()
	end
end

function RDX.Streaming.RequestAnimDict(animDict, cb)
	if not HasAnimDictLoaded(animDict) then
		RequestAnimDict(animDict)
		while not HasAnimDictLoaded(animDict) do
			Wait(0)
		end
	end

	if cb ~= nil then
		cb()
	end
end
