RDX = {}
RDX.PlayerData = {}
RDX.PlayerLoaded = false
RDX.CurrentRequestId = 0
RDX.ServerCallbacks = {}
RDX.TimeoutCallbacks = {}

RDX.UI = {}
RDX.UI.HUD = {}
RDX.UI.HUD.RegisteredElements = {}
RDX.UI.Menu = {}
RDX.UI.Menu.RegisteredTypes = {}
RDX.UI.Menu.Opened = {}

RDX.Game = {}
RDX.Game.Utils = {}

RDX.Streaming = {}

RDX.SetTimeout = function(msec, cb)
	table.insert(RDX.TimeoutCallbacks, {
		time = GetGameTimer() + msec,
		cb   = cb
	})
	return #RDX.TimeoutCallbacks
end

RDX.ClearTimeout = function(i)
	RDX.TimeoutCallbacks[i] = nil
end

RDX.IsPlayerLoaded = function()
	return RDX.PlayerLoaded
end

RDX.GetPlayerData = function()
	return RDX.PlayerData
end

RDX.SetPlayerData = function(key, val)
	RDX.PlayerData[key] = val
end

RDX.ShowAdvancedNotification = function(title, subtitle, duration, dict, icon)
	TriggerEvent('rdx:showAdvancedNotification', title, subtitle, duration, dict, icon)
end

RDX.ShowLocationNotification = function(location, text, duration)
	TriggerEvent('rdx:showLocationNotification', location, text, duration)
end

RDX.ShowHelpNotification = function(text, duration)
	TriggerEvent('rdx:showHelpNotification', text, duration)
end

RDX.TriggerServerCallback = function(name, cb, ...)
	RDX.ServerCallbacks[RDX.CurrentRequestId] = cb

	TriggerServerEvent('rdx:triggerServerCallback', name, RDX.CurrentRequestId, ...)

	if RDX.CurrentRequestId < 65535 then
		RDX.CurrentRequestId = RDX.CurrentRequestId + 1
	else
		RDX.CurrentRequestId = 0
	end
end

RDX.UI.HUD.SetDisplay = function(opacity)
	SendNUIMessage({
		action  = 'setHUDDisplay',
		opacity = opacity
	})
end

RDX.UI.HUD.RegisterElement = function(name, index, priority, html, data)
	local found = false

	for i=1, #RDX.UI.HUD.RegisteredElements, 1 do
		if RDX.UI.HUD.RegisteredElements[i] == name then
			found = true
			break
		end
	end

	if found then
		return
	end

	table.insert(RDX.UI.HUD.RegisteredElements, name)

	SendNUIMessage({
		action    = 'insertHUDElement',
		name      = name,
		index     = index,
		priority  = priority,
		html      = html,
		data      = data
	})

	RDX.UI.HUD.UpdateElement(name, data)
end

RDX.UI.HUD.RemoveElement = function(name)
	for i=1, #RDX.UI.HUD.RegisteredElements, 1 do
		if RDX.UI.HUD.RegisteredElements[i] == name then
			table.remove(RDX.UI.HUD.RegisteredElements, i)
			break
		end
	end

	SendNUIMessage({
		action    = 'deleteHUDElement',
		name      = name
	})
end

RDX.UI.HUD.UpdateElement = function(name, data)
	SendNUIMessage({
		action = 'updateHUDElement',
		name   = name,
		data   = data
	})
end

RDX.UI.Menu.RegisterType = function(type, open, close)
	RDX.UI.Menu.RegisteredTypes[type] = {
		open   = open,
		close  = close
	}
end

RDX.UI.Menu.Open = function(type, namespace, name, data, submit, cancel, change, close)
	local menu = {}

	menu.type      = type
	menu.namespace = namespace
	menu.name      = name
	menu.data      = data
	menu.submit    = submit
	menu.cancel    = cancel
	menu.change    = change

	menu.close = function()
		
		RDX.UI.Menu.RegisteredTypes[type].close(namespace, name)

		for i=1, #RDX.UI.Menu.Opened, 1 do
			if RDX.UI.Menu.Opened[i] then
				if RDX.UI.Menu.Opened[i].type == type and RDX.UI.Menu.Opened[i].namespace == namespace and RDX.UI.Menu.Opened[i].name == name then
					RDX.UI.Menu.Opened[i] = nil
				end
			end
		end

		if close then
			close()
		end

	end

	menu.update = function(query, newData)

		for i=1, #menu.data.elements, 1 do
			local match = true

			for k,v in pairs(query) do
				if menu.data.elements[i][k] ~= v then
					match = false
				end
			end

			if match then
				for k,v in pairs(newData) do
					menu.data.elements[i][k] = v
				end
			end
		end

	end

	menu.refresh = function()
		RDX.UI.Menu.RegisteredTypes[type].open(namespace, name, menu.data)
	end

	menu.setElement = function(i, key, val)
		menu.data.elements[i][key] = val
	end
	
	menu.setElements = function(newElements)
		menu.data.elements = newElements
	end

	menu.setTitle = function(val)
		menu.data.title = val
	end

	menu.removeElement = function(query)
		for i=1, #menu.data.elements, 1 do
			for k,v in pairs(query) do
				if menu.data.elements[i] then
					if menu.data.elements[i][k] == v then
						table.remove(menu.data.elements, i)
						break
					end
				end

			end
		end
	end

	table.insert(RDX.UI.Menu.Opened, menu)
	RDX.UI.Menu.RegisteredTypes[type].open(namespace, name, data)

	return menu
end

RDX.UI.Menu.Close = function(type, namespace, name)
	for i=1, #RDX.UI.Menu.Opened, 1 do
		if RDX.UI.Menu.Opened[i] then
			if RDX.UI.Menu.Opened[i].type == type and RDX.UI.Menu.Opened[i].namespace == namespace and RDX.UI.Menu.Opened[i].name == name then
				RDX.UI.Menu.Opened[i].close()
				RDX.UI.Menu.Opened[i] = nil
			end
		end
	end
end

RDX.UI.Menu.CloseAll = function()
	for i=1, #RDX.UI.Menu.Opened, 1 do
		if RDX.UI.Menu.Opened[i] then
			RDX.UI.Menu.Opened[i].close()
			RDX.UI.Menu.Opened[i] = nil
		end
	end
end

RDX.UI.Menu.GetOpened = function(type, namespace, name)
	for i=1, #RDX.UI.Menu.Opened, 1 do
		if RDX.UI.Menu.Opened[i] then
			if RDX.UI.Menu.Opened[i].type == type and RDX.UI.Menu.Opened[i].namespace == namespace and RDX.UI.Menu.Opened[i].name == name then
				return RDX.UI.Menu.Opened[i]
			end
		end
	end
end

RDX.UI.Menu.GetOpenedMenus = function()
	return RDX.UI.Menu.Opened
end

RDX.UI.Menu.IsOpen = function(type, namespace, name)
	return RDX.UI.Menu.GetOpened(type, namespace, name) ~= nil
end

RDX.UI.Menu.AreMenusOpen = function()
	return #RDX.UI.Menu.Opened > 0
end

RDX.UI.ShowInventoryItemNotification = function(add, item, count)
	SendNUIMessage({
		action = 'inventoryNotification',
		add    = add,
		item   = item,
		count  = count
	})
end

RDX.Game.CreatePed = function(pedModel, pedCoords, isNetworked)
	local vector = type(pedCoords) == "vector4" and pedCoords or type(pedCoords) == "vector3" and vector4(pedCoords, 0.0)
	
	RDX.Streaming.RequestModel(pedModel)
	return CreatePed(pedModel, vector, isNetworked, false, true, true) -- FIX: not sure what the last two booleans are
end

RDX.Game.CreatePedInsideVehicle = function(vehicle, pedModel, seatIndex)
	RDX.Streaming.RequestModel(pedModel)
	return CreatePedInsideVehicle(vehicle, pedModel, seatIndex or -1, true, true, true) -- FIX: not sure what the last tree booleans are
end

RDX.Game.CreatePedOnMount = function(mount, pedModel, index)
	RDX.Streaming.RequestModel(pedModel)
	return CreatePedOnMount(mount, pedModel, index or -1, true, true, true, true) -- FIX: not sure what the last four booleans are
end

RDX.Game.SpawnPed = function(model, coords, heading, cb)
	local ped = RDX.Game.CreatePed(model, vector4(coords.x, coords.y, coords.z, heading), true)

	SetPedOutfitPreset(ped, true, false)
	Citizen.InvokeNative(0x283978A15512B2FE, ped, true)
	SetEntityAsMissionEntity(ped, true, false)
	RequestCollisionAtCoord(coords.x, coords.y, coords.z)

	if cb then
		cb(ped)
	end
end

RDX.Game.DeletePed = function(ped)
	SetEntityAsMissionEntity(ped, false, true)
	DeletePed(ped)
end

RDX.Game.PlayAnim = function(animDict, animName, upperbodyOnly, duration)
	-- Quick simple function to run an animation
	local flags = upperbodyOnly == true and 16 or 0
	local runTime = duration ~= nil and duration or -1
	
	RDX.Streaming.RequestAnimDict(animDict)
	TaskPlayAnim(PlayerPedId(), animDict, animName, 8.0, 1.0, runTime, flags, 0.0, false, false, true)
	RemoveAnimDict(animDict)
end

RDX.Game.PlayFacialAnim = function(animDict, animName)
	RDX.Streaming.RequestAnimDict(animDict)
	SetFacialIdleAnimOverride(PlayerPedId(), animName, animDict)
	RemoveAnimDict(animDict)
end

RDX.Game.Teleport = function(entity, coords, cb)
	local vector = type(coords) == "vector4" and coords or type(coords) == "vector3" and vector4(coords, 0.0) or vec(coords.x, coords.y, coords.z, coords.heading or 0.0)
	
	if DoesEntityExist(entity) then
		RequestCollisionAtCoord(vector.xyz)
		while not HasCollisionLoadedAroundEntity(entity) do
			Wait(0)
		end

		Citizen.InvokeNative(0x203BEFFDBE12E96A, entity, vector, false, false, false)
	end

	if cb then
		cb()
	end
end

RDX.Game.SpawnObject = function(model, coords, cb, networked, mission, dynamic)
	local vector = type(coords) == "vector3" and coords or vec(coords.x, coords.y, coords.z)
	networked = networked == nil and true or false
	mission = mission == nil and false or true
	dynamic = dynamic ~= nil and true or false
	
	CreateThread(function()
		RDX.Streaming.RequestModel(model)
		
		-- The below has to be done just for CreateObject since for some reason CreateObjects model argument is set
		-- as an Object instead of a hash so it doesn't automatically hash the item
		model = type(model) == 'number' and model or GetHashKey(model)
		local obj = CreateObject(model, vector.xyz, networked, mission, dynamic, false, false) -- FIX: not sure what the last two booleans are
		if cb then
			cb(obj)
		end
	end)
end

RDX.Game.SpawnLocalObject = function(model, coords, cb)
	-- Why have 2 separate functions for this? Just call the other one with an extra param
	RDX.Game.SpawnObject(model, coords, cb, false)
end

RDX.Game.DeleteObject = function(object)
	SetEntityAsMissionEntity(object, false, true)
	DeleteObject(object)
end

RDX.Game.SpawnVehicle = function(model, coords, heading, cb, networked)
	local vector = type(coords) == "vector3" and coords or vec(coords.x, coords.y, coords.z)
	networked = networked == nil and true or false

	CreateThread(function()
		RDX.Streaming.RequestModel(model)

		local vehicle = CreateVehicle(model, vector.xyz, heading, networked, true, false) -- FIX: not sure what the last two booleans are

		--[[ FIX: natives not found or not implemented yet
		local id = NetworkGetNetworkIdFromEntity(vehicle)
		SetNetworkIdCanMigrate(id, true)
		]]

		SetEntityAsMissionEntity(vehicle, true, false)
		SetVehicleHasBeenOwnedByPlayer(vehicle, true)
		SetModelAsNoLongerNeeded(model)

		RequestCollisionAtCoord(vector.xyz)
		while not HasCollisionLoadedAroundEntity(vehicle) do
			Wait(0)
		end

		if cb then
			cb(vehicle)
		end
	end)
end

RDX.Game.SpawnLocalVehicle = function(model, coords, heading, cb)
	-- Why have 2 separate functions for this? Just call the other one with an extra param
	RDX.Game.SpawnVehicle(model, coords, heading, cb, false)
end

RDX.Game.DeleteVehicle = function(vehicle)
	SetEntityAsMissionEntity(vehicle, false, true)
	DeleteVehicle(vehicle)
end

RDX.Game.IsVehicleEmpty = function(vehicle)
	local passengers = GetVehicleNumberOfPassengers(vehicle)
	local driverSeatFree = IsVehicleSeatFree(vehicle, -1)

	return passengers == 0 and driverSeatFree
end

RDX.Game.GetPeds = function(onlyOtherPeds)
	local peds, myPed = {}, PlayerPedId()

	for ped in EnumeratePeds() do
		if ((onlyOtherPeds and ped ~= myPed) or not onlyOtherPeds) then
			table.insert(peds, ped)
		end
	end

	return peds
end

RDX.Game.GetObjects = function()
	local objects = {}

	for object in EnumerateObjects() do
		table.insert(objects, object)
	end

	return objects
end

RDX.Game.GetVehicles = function()
	local vehicles = {}

	for vehicle in EnumerateVehicles() do
		table.insert(vehicles, vehicle)
	end

	return vehicles
end

RDX.Game.GetPlayers = function(onlyOtherPlayers, returnKeyValue, returnPeds)
	local players, myPlayer = {}, PlayerId()
	local activePlayers = GetActivePlayers()

	for i = 1, #activePlayers do
		local player = activePlayers[i]
		local ped = GetPlayerPed(player)

		if DoesEntityExist(ped) and ((onlyOtherPlayers and player ~= myPlayer) or not onlyOtherPlayers) then
			if returnKeyValue then
				players[player] = ped
			else
				table.insert(players, returnPeds and ped or player)
			end
		end
	end

	return players
end

RDX.Game.GetClosestEntity = function(entities, isPlayerEntities, coords, modelFilter)
	local closestEntity, closestEntityDistance, filteredEntities = -1, -1, nil

	if coords then
		coords = vector3(coords.x, coords.y, coords.z)
	else
		local playerPed = PlayerPedId()
		coords = GetEntityCoords(playerPed)
	end

	if modelFilter then
		filteredEntities = {}

		for k,entity in pairs(entities) do
			if modelFilter[GetEntityModel(entity)] then
				table.insert(filteredEntities, entity)
			end
		end
	end

	for k,entity in pairs(filteredEntities or entities) do
		local distance = #(coords - GetEntityCoords(entity))

		if closestEntityDistance == -1 or distance < closestEntityDistance then
			closestEntity, closestEntityDistance = isPlayerEntities and k or entity, distance
		end
	end

	return closestEntity, closestEntityDistance
end

RDX.Game.GetClosestObject = function(coords, modelFilter) return RDX.Game.GetClosestEntity(RDX.Game.GetObjects(), false, coords, modelFilter) end
RDX.Game.GetClosestPed = function(coords, modelFilter) return RDX.Game.GetClosestEntity(RDX.Game.GetPeds(true), false, coords, modelFilter) end
RDX.Game.GetClosestPlayer = function(coords) return RDX.Game.GetClosestEntity(RDX.Game.GetPlayers(true, true), true, coords, nil) end
RDX.Game.GetClosestVehicle = function(coords, modelFilter) return RDX.Game.GetClosestEntity(RDX.Game.GetVehicles(), false, coords, modelFilter) end
RDX.Game.GetPlayersInArea = function(coords, maxDistance) return EnumerateEntitiesWithinDistance(RDX.Game.GetPlayers(true, true), true, coords, maxDistance) end
RDX.Game.GetVehiclesInArea = function(coords, maxDistance) return EnumerateEntitiesWithinDistance(RDX.Game.GetVehicles(), false, coords, maxDistance) end
RDX.Game.IsSpawnPointClear = function(coords, maxDistance) return #RDX.Game.GetVehiclesInArea(coords, maxDistance) == 0 end

RDX.Game.GetHorseInDirection = function()
	local playerPed    = PlayerPedId()
	local playerCoords = GetEntityCoords(playerPed)
	local inDirection  = GetOffsetFromEntityInWorldCoords(playerPed, 0.0, 5.0, 0.0)
	local rayHandle    = StartShapeTestRay(playerCoords, inDirection, 10, playerPed, 0)
	local numRayHandle, hit, endCoords, surfaceNormal, entityHit = GetShapeTestResult(rayHandle)

	if hit == 1 and IsEntityAPed(entityHit) and GetPedType(entityHit) == 28 then
		return entityHit
	end

	return nil
end

RDX.Game.GetVehicleInDirection = function()
	local playerPed    = PlayerPedId()
	local playerCoords = GetEntityCoords(playerPed)
	local inDirection  = GetOffsetFromEntityInWorldCoords(playerPed, 0.0, 5.0, 0.0)
	local rayHandle    = StartShapeTestRay(playerCoords, inDirection, 10, playerPed, 0)
	local numRayHandle, hit, endCoords, surfaceNormal, entityHit = GetShapeTestResult(rayHandle)

	if hit == 1 and GetEntityType(entityHit) == 2 then
		return entityHit
	end

	return nil
end

RDX.Game.GetVehicleProperties = function(vehicle)
	if DoesEntityExist(vehicle) then
		local extras = {}

		for id=0, 12 do
			if DoesExtraExist(vehicle, id) then
				local state = IsVehicleExtraTurnedOn(vehicle, id) == 1
				extras[tostring(id)] = state
			end
		end

		return {
			model             = GetEntityModel(vehicle),

			bodyHealth        = RDX.Math.Round(GetVehicleBodyHealth(vehicle), 1),
			engineHealth      = RDX.Math.Round(GetVehicleEngineHealth(vehicle), 1),

			extras            = extras
		}
	else
		return
	end
end

RDX.Game.SetVehicleProperties = function(vehicle, props)
	if DoesEntityExist(vehicle) then
		if props.bodyHealth then SetVehicleBodyHealth(vehicle, props.bodyHealth + 0.0) end
		if props.engineHealth then SetVehicleEngineHealth(vehicle, props.engineHealth + 0.0) end

		if props.extras then
			for id,enabled in pairs(props.extras) do
				if enabled then
					SetVehicleExtra(vehicle, tonumber(id), 0)
				else
					SetVehicleExtra(vehicle, tonumber(id), 1)
				end
			end
		end
	end
end

RDX.Game.Utils.DrawText3D = function(coords, text, size, font, color)
	coords = vector3(coords.x, coords.y, coords.z)
	if not color then color = { r = 255, g = 255, b = 255, a = 255 } end

	local camCoords = Citizen.InvokeNative(0x595320200B98596E, Citizen.ReturnResultAnyway(), Citizen.ResultAsVector())
	local distance = #(camCoords - coords)

	if not size then size = 1 end
	if not font then font = 0 end

	local scale = (size / distance) * 2
	local fov = (1 / GetGameplayCamFov()) * 100
	scale = scale * fov

	local onScreen, x, y = GetScreenCoordFromWorldCoord(coords.x, coords.y, coords.z)

	if (onScreen) then
		SetTextScale(0.0 * scale, 0.55 * scale)
		SetTextColor(color.r, color.g, color.b, color.a)
		SetTextFontForCurrentCommand(font)
		SetTextDropshadow(0, 0, 0, 255)
		SetTextCentre(true)
		DisplayText(CreateVarString(10, 'LITERAL_STRING', text), x, y)
	end
end

RDX.Game.Utils.DrawText2D = function(coords, text, width, height, center, font, color)
	if not color then color = { r = 255, g = 255, b = 255, a = 255 } end
	if not font then font = 0 end
	if center == nil then center = true end

	SetTextScale(width, height)
	Citizen.InvokeNative(0xADA9255D, font)
	SetTextColor(color.r, color.g, color.b, color.a)
	SetTextCentre(center)
	SetTextDropshadow(1, 0, 0, 0, 255)
	DisplayText(CreateVarString(10, "LITERAL_STRING", text, Citizen.ResultAsLong()), coords.x, coords.y)
end

RDX.ShowInventory = function()
	local playerPed = PlayerPedId()
	local elements, currentWeight = {}, 0

	for k,v in pairs(RDX.PlayerData.accounts) do
		if v.money > 0 then
			local formattedMoney = _U('locale_currency', RDX.Math.GroupDigits(v.money))
			local canDrop = v.name ~= 'bank'

			table.insert(elements, {
				label = ('%s: %s'):format(v.label, formattedMoney),
				count = v.money,
				type = 'item_account',
				value = v.name,
				usable = false,
				rare = false,
				canRemove = canDrop,
				submenu = true,
				description = _U('account_description', v.label)
			})
		end
	end

	for k,v in ipairs(RDX.PlayerData.inventory) do
		if v.count > 0 then
			currentWeight = currentWeight + (v.weight * v.count)

			table.insert(elements, {
				label = ('%s - x%s'):format(v.label, v.count),
				count = v.count,
				weight = v.weight,
				type = 'item_standard',
				value = v.name,
				usable = v.usable,
				rare = v.rare,
				canRemove = v.canRemove,
				submenu = true,
				description = _U('item_description', v.weight)
			})
		end
	end

	for k,v in ipairs(Config.Weapons) do
		local weaponHash = GetHashKey(v.name)

		if HasPedGotWeapon(playerPed, weaponHash, false) and v.name ~= 'WEAPON_UNARMED' then
			local ammo, label = GetAmmoInPedWeapon(playerPed, weaponHash)

			if v.ammo then
				label = ('%s - %s %s'):format(v.label, ammo, v.ammo.label)
			else
				label = v.label
			end

			table.insert(elements, {
				label = label,
				count = 1,
				type = 'item_weapon',
				value = v.name,
				usable = false,
				rare = false,
				ammo = ammo,
				canGiveAmmo = (v.ammo ~= nil),
				canRemove = true,
				submenu = true
			})
		end
	end

	RDX.UI.Menu.Open('default', GetCurrentResourceName(), 'inventory', {
		title    = _U('inventory'),
		subtitle = ('%s / %s'):format(currentWeight, RDX.PlayerData.maxWeight),
		align    = 'bottom-right',
		elements = elements
	}, function(data, menu)
		menu.close()
		local player, distance = RDX.Game.GetClosestPlayer()
		local elements = {}

		if data.current.usable then
			table.insert(elements, {label = _U('use'), action = 'use', type = data.current.type, value = data.current.value})
		end

		if data.current.canRemove then
			if player ~= -1 and distance <= 3.0 then
				table.insert(elements, {label = _U('give'), action = 'give', type = data.current.type, value = data.current.value})
			end

			table.insert(elements, {label = _U('remove'), action = 'remove', type = data.current.type, value = data.current.value})
		end

		if data.current.type == 'item_weapon' and data.current.canGiveAmmo and data.current.ammo > 0 and player ~= -1 and distance <= 3.0 then
			table.insert(elements, {label = _U('giveammo'), action = 'give_ammo', type = data.current.type, value = data.current.value})
		end

		RDX.UI.Menu.Open('default', GetCurrentResourceName(), 'inventory_item', {
			title    = data.current.label,
			align    = 'bottom-right',
			elements = elements,
			subtitle = (data.current.weight and string.format(_U('item_description', string.format('%s / %s', data.current.weight * data.current.count, RDX.PlayerData.maxWeight))) or '')
		}, function(data1, menu1)
			local item, type = data1.current.value, data1.current.type

			if data1.current.action == 'give' then
				local playersNearby = RDX.Game.GetPlayersInArea(GetEntityCoords(playerPed), 3.0)

				if #playersNearby > 0 then
					local players, elements = {}, {}

					for k,player in ipairs(playersNearby) do
						players[GetPlayerServerId(player)] = true
					end

					RDX.TriggerServerCallback('rdx:getPlayerNames', function(returnedPlayers)
						for playerId,playerName in pairs(returnedPlayers) do
							table.insert(elements, {
								label = playerName,
								playerId = playerId
							})
						end

						RDX.UI.Menu.Open('default', GetCurrentResourceName(), 'give_item_to', {
							title    = _U('give_to'),
							align    = 'bottom-right',
							elements = elements
						}, function(data2, menu2)
							local selectedPlayer, selectedPlayerId = GetPlayerFromServerId(data2.current.playerId), data2.current.playerId
							playersNearby = RDX.Game.GetPlayersInArea(GetEntityCoords(playerPed), 3.0)
							playersNearby = RDX.Table.Set(playersNearby)

							if playersNearby[selectedPlayer] then
								local selectedPlayerPed = GetPlayerPed(selectedPlayer)

								if IsPedOnFoot(selectedPlayerPed) then
									if type == 'item_weapon' then
										TriggerServerEvent('rdx:giveInventoryItem', selectedPlayerId, type, item, nil)
										menu2.close()
										menu1.close()
									else
										RDX.UI.Menu.Open('dialog', GetCurrentResourceName(), 'inventory_item_count_give', {
											title = _U('amount')
										}, function(data3, menu3)
											local quantity = tonumber(data3.value)

											if quantity then
												TriggerServerEvent('rdx:giveInventoryItem', selectedPlayerId, type, item, quantity)
												menu3.close()
												menu2.close()
												menu1.close()
											else
												RDX.ShowNotification(_U('amount_invalid'))
											end
										end, function(data3, menu3)
											menu3.close()
										end)
									end
								else
									RDX.ShowNotification(_U('in_vehicle'))
								end
							else
								RDX.ShowNotification(_U('players_nearby'))
								menu2.close()
							end
						end, function(data2, menu2)
							menu2.close()
						end)
					end, players)
				else
					RDX.ShowNotification(_U('players_nearby'))
				end
			elseif data1.current.action == 'remove' then
				if IsPedOnFoot(playerPed) and not IsPedFalling(playerPed) then
					-- FIX: Anim unknown yet
					--local dict, anim = 'weapons@first_person@aim_rng@generic@projectile@sticky_bomb@', 'plant_floor'
					--RDX.Streaming.RequestAnimDict(dict)

					if type == 'item_weapon' then
						menu1.close()
						-- FIX: Anim unknown yet
						--TaskPlayAnim(playerPed, dict, anim, 8.0, 1.0, 1000, 16, 0.0, false, false, false)
						--Wait(1000)
						TriggerServerEvent('rdx:removeInventoryItem', type, item)
					else
						RDX.UI.Menu.Open('dialog', GetCurrentResourceName(), 'inventory_item_count_remove', {
							title = _U('amount')
						}, function(data2, menu2)
							local quantity = tonumber(data2.value)

							if quantity then
								menu2.close()
								menu1.close()
								-- FIX: Anim unknown yet
								--TaskPlayAnim(playerPed, dict, anim, 8.0, 1.0, 1000, 16, 0.0, false, false, false)
								--Wait(1000)
								TriggerServerEvent('rdx:removeInventoryItem', type, item, quantity)
							else
								RDX.ShowNotification(_U('amount_invalid'))
							end
						end, function(data2, menu2)
							menu2.close()
						end)
					end
				end
			elseif data1.current.action == 'use' then
				TriggerServerEvent('rdx:useItem', item)
			elseif data1.current.action == 'give_ammo' then
				local closestPlayer, closestDistance = RDX.Game.GetClosestPlayer()
				local closestPed = GetPlayerPed(closestPlayer)
				local pedAmmo = GetAmmoInPedWeapon(playerPed, GetHashKey(item))

				if IsPedOnFoot(closestPed) then
					if closestPlayer ~= -1 and closestDistance < 3.0 then
						if pedAmmo > 0 then
							RDX.UI.Menu.Open('dialog', GetCurrentResourceName(), 'inventory_item_count_give', {
								title = _U('amountammo')
							}, function(data2, menu2)
								local quantity = tonumber(data2.value)

								if quantity then
									if pedAmmo >= quantity and quantity > 0 then
										TriggerServerEvent('rdx:giveInventoryItem', GetPlayerServerId(closestPlayer), 'item_ammo', item, quantity)
										menu2.close()
										menu1.close()
									else
										RDX.ShowNotification(_U('noammo'))
									end
								else
									RDX.ShowNotification(_U('amount_invalid'))
								end
							end, function(data2, menu2)
								menu2.close()
							end)
						else
							RDX.ShowNotification(_U('noammo'))
						end
					else
						RDX.ShowNotification(_U('players_nearby'))
					end
				else
					RDX.ShowNotification(_U('in_vehicle'))
				end
			end
		end, function(data1, menu1)
			RDX.UI.Menu.CloseAll()
			RDX.ShowInventory()
		end)
	end, function(data, menu)
		menu.close()
	end)
end

RegisterNetEvent('rdx:serverCallback')
AddEventHandler('rdx:serverCallback', function(requestId, ...)
	RDX.ServerCallbacks[requestId](...)
	RDX.ServerCallbacks[requestId] = nil
end)

-- SetTimeout
CreateThread(function()
	while true do
		Wait(0)
		local currTime = GetGameTimer()

		for i=1, #RDX.TimeoutCallbacks, 1 do
			if RDX.TimeoutCallbacks[i] then
				if currTime >= RDX.TimeoutCallbacks[i].time then
					RDX.TimeoutCallbacks[i].cb()
					RDX.TimeoutCallbacks[i] = nil
				end
			end
		end
	end
end)

RDX.Markers = {}
RDX.Markers.Table = {}

RDX.Markers.Add = function(mType, mPos, red, green, blue, alpha, rangeToShow, bobUpAndDown, mScale, mRot, mDir, faceCamera, textureDict, textureName)
	rangeToShow = rangeToShow ~= nil and rangeToShow or 50.0
	mScale = mScale ~= nil and mScale or vec(1, 1, 1)
	mDir = mDir ~= nil and mDir or vec(0, 0, 0)
	mRot = mRot ~= nil and mRot or vec(0, 0, 0)
	bobUpAndDown = bobUpAndDown or false
	faceCamera = faceCamera or false
	textureDict = textureDict or nil
	textureName = textureName or nil
	
	if textureDict ~= nil then
		RDX.Streaming.RequestStreamedTextureDict(textureDict)
	end
	
	local markerData = {
		range = rangeToShow,
		type = mType,
		pos = mPos,
		dir = mDir,
		rot = mRot,
		scale = mScale,
		r = red,
		g = green,
		b = blue,
		a = alpha,
		bob = bobUpAndDown,
		faceCam = faceCamera,
		dict = textureDict,
		name = textureName,
		isInside = false,
		deleteNow = false
	}
	local tableKey = tostring(markerData)
    RDX.Markers.Table[tableKey] = markerData

    return tableKey
end

RDX.Markers.Remove = function(markerKey)
	RDX.Markers.Table[markerKey].deleteNow = true
	local textureDict = RDX.Markers.Table[markerKey].dict
	if textureDict ~= nil then
		SetStreamedTextureDictAsNoLongerNeeded(textureDict)
	end
end

RDX.Markers.In = function(markerKey)
	return RDX.Markers.Table[markerKey].isInside
end

local markerWait = 500
CreateThread(function()
	while true do
		Wait(markerWait)
		local ped = PlayerPedId()
		local pedCoords = GetEntityCoords(ped)
		markerWait = 500
		
		for markerKey, marker in pairs(RDX.Markers.Table) do
			if marker.deleteNow then
				marker = nil
			else
				if #(pedCoords - marker.pos) < marker.range then
					markerWait = 1
					DrawMarker(marker.type, marker.pos, marker.dir, marker.rot, marker.scale, marker.r, marker.g, marker.b, marker.a, marker.bob, marker.faceCam, 0, false, marker.dict, marker.name, false)
				end
				if #(pedCoords - marker.pos) < marker.scale.x then
					marker.isInside = true
				else
					marker.isInside = false
				end
			end
		end
	end
end)
