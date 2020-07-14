RDX.Trace = function(msg)
	if Config.EnableDebug then
		print(('[RDX] [^2TRACE^7] %s^7'):format(msg))
	end
end

RDX.SetTimeout = function(msec, cb)
	local id = RDX.TimeoutCount + 1

	SetTimeout(msec, function()
		if RDX.CancelledTimeouts[id] then
			RDX.CancelledTimeouts[id] = nil
		else
			cb()
		end
	end)

	RDX.TimeoutCount = id

	return id
end

RDX.RegisterCommand = function(name, group, cb, allowConsole, suggestion)
	if type(name) == 'table' then
		for k,v in ipairs(name) do
			RDX.RegisterCommand(v, group, cb, allowConsole, suggestion)
		end

		return
	end

	if RDX.RegisteredCommands[name] then
		print(('[RDX] [^3WARNING^7] An command "%s" is already registered, overriding command'):format(name))

		if RDX.RegisteredCommands[name].suggestion then
			TriggerClientEvent('chat:removeSuggestion', -1, ('/%s'):format(name))
		end
	end

	if suggestion then
		if not suggestion.arguments then suggestion.arguments = {} end
		if not suggestion.help then suggestion.help = '' end

		TriggerClientEvent('chat:addSuggestion', -1, ('/%s'):format(name), suggestion.help, suggestion.arguments)
	end

	RDX.RegisteredCommands[name] = {group = group, cb = cb, allowConsole = allowConsole, suggestion = suggestion}

	RegisterCommand(name, function(playerId, args, rawCommand)
		local command = RDX.RegisteredCommands[name]

		if not command.allowConsole and playerId == 0 then
			print(('[RDX] [^3WARNING^7] %s'):format(_U('commanderror_console')))
		else
			local xPlayer, error = RDX.GetPlayerFromId(playerId), nil

			local joinedArgs, argsToJoin, isLongArg = {}, {}, false
			for _,v in ipairs(args) do
				if RDX.String.StartsWith(v, '"') then
					-- if long arg was started, append those that remain
					if isLongArg then
						for _,v2 in ipairs(argsToJoin) do
							table.insert(joinedArgs, v2)
						end
					end

					if RDX.String.EndsWith(v, '"') then
						isLongArg = false
						table.insert(joinedArgs, v)
					else
						isLongArg = true
						table.insert(argsToJoin, v)
					end
				elseif RDX.String.EndsWith(v, '"') then
					if isLongArg then
						table.insert(argsToJoin, v)
						local joinedArg = RDX.Table.Join(argsToJoin, ' ')
						table.insert(joinedArgs, joinedArg:sub(2, #joinedArg - 1))
						isLongArg = false

						local count = #argsToJoin
						for i=1, count do argsToJoin[i] = nil end
					else
						table.insert(joinedArgs, v)
					end
				elseif isLongArg then
					table.insert(argsToJoin, v)
				else
					table.insert(joinedArgs, v)
				end
			end

			-- add unclosed args as normal args
			if isLongArg then
				for _,v in ipairs(argsToJoin) do
					table.insert(joinedArgs, v)
				end
			end

			if command.suggestion then
				if command.suggestion.validate then
					if #joinedArgs ~= #command.suggestion.arguments then
						error = _U('commanderror_argumentmismatch', #joinedArgs, #command.suggestion.arguments)
					end
				end

				if not error and command.suggestion.arguments then
					local newArgs = {}

					for k,v in ipairs(command.suggestion.arguments) do
						if v.type then
							if v.type == 'number' then
								local newArg = tonumber(joinedArgs[k])

								if newArg then
									newArgs[v.name] = newArg
								else
									error = _U('commanderror_argumentmismatch_number', k)
								end
							elseif v.type == 'player' or v.type == 'playerId' then
								local targetPlayer = tonumber(joinedArgs[k])

								if joinedArgs[k] == 'me' then targetPlayer = playerId end

								if targetPlayer then
									local xTargetPlayer = RDX.GetPlayerFromId(targetPlayer)

									if xTargetPlayer then
										if v.type == 'player' then
											newArgs[v.name] = xTargetPlayer
										else
											newArgs[v.name] = targetPlayer
										end
									else
										error = _U('commanderror_invalidplayerid')
									end
								else
									error = _U('commanderror_argumentmismatch_number', k)
								end
							elseif v.type == 'string' then
								newArgs[v.name] = joinedArgs[k]
							elseif v.type == 'item' then
								if RDX.Items[joinedArgs[k]] then
									newArgs[v.name] = joinedArgs[k]
								else
									error = _U('commanderror_invaliditem')
								end
							elseif v.type == 'weapon' then
								if RDX.GetWeapon(joinedArgs[k]) then
									newArgs[v.name] = string.upper(joinedArgs[k])
								else
									error = _U('commanderror_invalidweapon')
								end
							elseif v.type == 'any' then
								newArgs[v.name] = joinedArgs[k]
							end
						end

						if error then break end
					end

					args = newArgs
				end
			end

			if error then
				if playerId == 0 then
					print(('[RDX] [^3WARNING^7] %s^7'):format(error))
				else
					xPlayer.triggerEvent('chat:addMessage', {args = {'^1SYSTEM', error}})
				end
			else
				cb(xPlayer or false, args, function(msg)
					if playerId == 0 then
						print(('[RDX] [^3WARNING^7] %s^7'):format(msg))
					else
						xPlayer.triggerEvent('chat:addMessage', {args = {'^1SYSTEM', msg}})
					end
				end)
			end
		end
	end, true)

	if type(group) == 'table' then
		for k,v in ipairs(group) do
			ExecuteCommand(('add_ace group.%s command.%s allow'):format(v, name))
		end
	else
		ExecuteCommand(('add_ace group.%s command.%s allow'):format(group, name))
	end
end

RDX.ClearTimeout = function(id)
	RDX.CancelledTimeouts[id] = true
end

RDX.RegisterServerCallback = function(name, cb)
	RDX.ServerCallbacks[name] = cb
end

RDX.TriggerServerCallback = function(name, requestId, source, cb, ...)
	if RDX.ServerCallbacks[name] then
		RDX.ServerCallbacks[name](source, cb, ...)
	else
		print(('[RDX] [^3WARNING^7] Server callback "%s" does not exist. Make sure that the server sided file really is loading, an error in that file might cause it to not load.'):format(name))
	end
end

RDX.SavePlayer = function(xPlayer, cb)
	MySQL.Async.execute('UPDATE characters SET accounts = @accounts, job = @job, job_grade = @job_grade, loadout = @loadout, position = @position, inventory = @inventory WHERE identifier = @identifier AND character_id = @character_id', {
		['@accounts'] = json.encode(xPlayer.getAccounts(true)),
		['@job'] = xPlayer.job.name,
		['@job_grade'] = xPlayer.job.grade,
		['@group'] = xPlayer.getGroup(),
		['@loadout'] = json.encode(xPlayer.getLoadout(true)),
		['@position'] = json.encode(xPlayer.getCoords()),
		['@identifier'] = xPlayer.getIdentifier(),
		['@character_id'] = xPlayer.getCharacterId(),
		['@inventory'] = json.encode(xPlayer.getInventory(true))
	}, cb)
end

RDX.SavePlayers = function(finishedCB)
	CreateThread(function()
		local savedPlayers = 0
		local playersToSave = #RDX.Players
		local tasks = Async.CreatePool()
	
		-- Save Each player
		for _, xPlayer in ipairs(RDX.Players) do
			tasks.add(function(cb)
				RDX.SavePlayer(xPlayer, function(rowsChanged)
					if rowsChanged == 1 then
						print(('[RDX] [^2INFO^7] Saved %s'):format(xPlayer.getName()))
						savedPlayers = savedPlayers	+ 1
					end
				end)
			end)
		end

		-- Call the callback when done
		tasks.startParallelLimitAsync(5, function(results)
			if playersToSave == savedPlayers then
				finishedCB(true)
			else
				finishedCB(false)
			end
		end)
	end)
end

RDX.StartDBSync = function()
	function saveData()
		RDX.SavePlayers(function(result)
			if result then
				print('[RDX] [^2INFO^7] Automatically saved all player data')
			else
				print('[RDX] [^3WARNING^7] Failed to automatically save player data! This may be caused by an internal error on the MySQL server.')
			end
		end)
		SetTimeout(10 * 60 * 1000, saveData)
	end

	SetTimeout(10 * 60 * 1000, saveData)
end

RDX.GetPlayers = function()
	local sources = {}

	for k,v in pairs(RDX.Players) do
		table.insert(sources, k)
	end

	return sources
end

RDX.GetPlayerFromId = function(source)
	return RDX.Players[tonumber(source)]
end

RDX.GetPlayerFromIdentifier = function(identifier)
	for k,v in pairs(RDX.Players) do
		if v.identifier == identifier then
			return v
		end
	end
end

RDX.GetPlayerFromIdentifierAndCharacterId = function(identifier, characterId)
	for k,v in pairs(RDX.Players) do
		if v.identifier == identifier and v.characterId == characterId then
			return v
		end
	end
end

RDX.RegisterUsableItem = function(item, cb)
	RDX.UsableItemsCallbacks[item] = cb
end

RDX.UseItem = function(source, item)
	RDX.UsableItemsCallbacks[item](source)
end

RDX.GetItemLabel = function(item)
	if RDX.Items[item] then
		return RDX.Items[item].label
	end
end

RDX.CreatePickup = function(type, name, count, label, playerId, components)
    local pickupId = (RDX.PickupId == 65635 and 0 or RDX.PickupId + 1)
    local xPlayer = RDX.GetPlayerFromId(playerId)
    local pedCoords
    
    if RDX.IsInfinity then
        pedCoords = GetEntityCoords(GetPlayerPed(playerId))
    end

    RDX.Pickups[pickupId] = {
        type  = type,
        name  = name,
        count = count,
        label = label,
        coords = xPlayer.getCoords(),
    }

    if type == 'item_weapon' then
        RDX.Pickups[pickupId].components = components
    end

    TriggerClientEvent('rdx:createPickup', -1, pickupId, label, playerId, type, name, components, RDX.IsInfinity, pedCoords)
    RDX.PickupId = pickupId
end

RDX.DoesJobExist = function(job, grade)
	grade = tostring(grade)

	if job and grade then
		if RDX.Jobs[job] and RDX.Jobs[job].grades[grade] then
			return true
		end
	end

	return false
end

RDX.GetPlayerIdentifiers = function(playerId)
	local identifier
	local license
	
	for k,v in ipairs(GetPlayerIdentifiers(playerId)) do
		if string.match(v, Config.PrimaryIdentifier) then
			identifier = v
		end
		
		if string.match(v, 'license:') then
			license = v
		end
	end
	
	return identifier, license
end

if RDX.IsOneSync then
	RDX.Game = {}

	RDX.Game.SpawnVehicle = function(model, coords)
		local vector = type(coords) == "vector4" and coords or type(coords) == "vector3" and vector4(coords, 0.0)
		return CreateVehicle(model, vector.xyzw, true, false)
	end

	RDX.Game.CreatePed = function(pedModel, pedCoords, pedType)
		local vector = type(pedCoords) == "vector4" and pedCoords or type(pedCoords) == "vector3" and vector4(pedCoords, 0.0)
		pedType = pedType ~= nil and pedType or 4
		return CreatePed(pedType, pedModel, vector.xyzw, true)
	end

	RDX.Game.SpawnObject = function(model, coords, dynamic)
		model = type(model) == 'number' and model or GetHashKey(model)
		dynamic = dynamic ~= nil and true or false
		return CreateObjectNoOffset(model, coords.xyz, true, dynamic)
	end
end