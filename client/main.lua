local isLoadoutLoaded, isPaused, isDead, isFirstSpawn, pickups = false, false, false, true, {}

CreateThread(function()
	while true do
		Wait(0)

		if NetworkIsPlayerActive(PlayerId()) then
			TriggerEvent('rdx:onPlayerJoined')
			TriggerServerEvent('rdx:onPlayerJoined')
			break
		end
	end
end)

RegisterNetEvent('rdx:playerLoaded')
AddEventHandler('rdx:playerLoaded', function(playerData)
	RDX.PlayerData = playerData

	local playerPed = PlayerPedId()

	if Config.EnablePvP then
		Citizen.InvokeNative(0xF808475FA571D823, true) --enable friendly fire
		NetworkSetFriendlyFireOption(true)
		SetRelationshipBetweenGroups(5, `PLAYER`, `PLAYER`)
	end

	if Config.RevealMap then
		Citizen.InvokeNative(0x4B8F743A4A6D2FF8, true)
	end

	if Config.EnableHud then
		for k,v in ipairs(playerData.accounts) do
			local accountTpl = '<div><img class="money" src="img/accounts/' .. v.name .. '.png"/>&nbsp;{{money}}</div>'
			RDX.UI.HUD.RegisterElement('account_' .. v.name, k, 0, accountTpl, {money = RDX.Math.GroupDigits(v.money)})
		end

		local jobTpl = '<div>{{job_label}} - {{grade_label}}</div>'

		if playerData.job.grade_label == '' or playerData.job.grade_label == playerData.job.label then
			jobTpl = '<div>{{job_label}}</div>'
		end

		RDX.UI.HUD.RegisterElement('job', #playerData.accounts, 0, jobTpl, {
			job_label = playerData.job.label,
			grade_label = playerData.job.grade_label
		})
	end

	-- Using spawnmanager now to spawn the player, this is the right way to do it, and it transitions better.
	exports.spawnmanager:spawnPlayer({
		x = playerData.coords.x,
		y = playerData.coords.y,
		z = playerData.coords.z,
		heading = playerData.coords.heading,
		model = Config.DefaultPlayerModel,
		skipFade = false
	}, function()
		isLoadoutLoaded = true
		TriggerServerEvent('rdx:onPlayerSpawn')
		TriggerEvent('rdx:onPlayerSpawn')
		TriggerEvent('rdx:restoreLoadout')
		RDX.PlayerLoaded = true

		if Config.DisplayCoords then
			DisplayCoords()
		end
	end)
end)

RegisterNetEvent('es:activateMoney')
AddEventHandler('es:activateMoney', function(money)
	RDX.PlayerData.money = money
end)

RegisterNetEvent('rdx:setMaxWeight')
AddEventHandler('rdx:setMaxWeight', function(newMaxWeight) RDX.PlayerData.maxWeight = newMaxWeight end)

AddEventHandler('rdx:onPlayerSpawn', function() isDead = false end)
AddEventHandler('rdx:onPlayerDeath', function() isDead = true end)
--AddEventHandler('skinchanger:loadDefaultModel', function() isLoadoutLoaded = false end)

AddEventHandler('skinchanger:modelLoaded', function()
	while not RDX.PlayerLoaded do
		Wait(100)
	end

	TriggerEvent('rdx:restoreLoadout')
end)

AddEventHandler('rdx:restoreLoadout', function()
	local playerPed = PlayerPedId()
	local ammoTypes = {}

	RemoveAllPedWeapons(playerPed, true, true)

	for k,v in ipairs(RDX.PlayerData.loadout) do
		local weaponName = v.name
		local weaponHash = GetHashKey(weaponName)

		GiveWeaponToPed_2(playerPed, weaponHash, 0, false, false, 0, false, 0.5, 1.0, 0, false, 0, false)

		local ammoType = GetPedAmmoTypeFromWeapon(playerPed, weaponHash)

		for k2,v2 in ipairs(v.components) do
			local componentHash = RDX.GetWeaponComponent(weaponName, v2).hash

			GiveWeaponComponentToPed(playerPed, componentHash, weaponHash, true)
		end

		if not ammoTypes[ammoType] then
			SetPedAmmo(playerPed, weaponHash, v.ammo)
			ammoTypes[ammoType] = true
		end
	end

	isLoadoutLoaded = true
end)

RegisterNetEvent('rdx:setAccountMoney')
AddEventHandler('rdx:setAccountMoney', function(account)
	for k,v in ipairs(RDX.PlayerData.accounts) do
		if v.name == account.name then
			RDX.PlayerData.accounts[k] = account
			break
		end
	end

	if Config.EnableHud then
		RDX.UI.HUD.UpdateElement('account_' .. account.name, {
			money = RDX.Math.GroupDigits(account.money)
		})
	end
end)

RegisterNetEvent('rdx:addInventoryItem')
AddEventHandler('rdx:addInventoryItem', function(item, count, showNotification, newItem)
	local found = false

	for k,v in ipairs(RDX.PlayerData.inventory) do
		if v.name == item then
			RDX.UI.ShowInventoryItemNotification(true, v.label, count - v.count)
			RDX.PlayerData.inventory[k].count = count

			found = true
			break
		end
	end

	-- If the item wasn't found in your inventory -> run
	if(found == false and newItem --[[Just a check if there is a newItem]])then
		-- Add item newItem to the players inventory
		RDX.PlayerData.inventory[#RDX.PlayerData.inventory + 1] = {
			name = newItem.name,
			count = count,
			label = newItem.label,
			weight = newItem.weight,
			limit = newItem.limit,
			usable = newItem.usable,
			rare = newItem.rare,
			canRemove = newItem.canRemove
		}

		-- Show a notification that a new item was added
		RDX.UI.ShowInventoryItemNotification(true, newItem.label, count)
	else
		-- Don't show this error for now
		-- print("^1[ExtendedMode]^7 Error: there is an error while trying to add an item to the inventory, item name: " .. item)
	end

	if showNotification then
		RDX.UI.ShowInventoryItemNotification(true, item, count)
	end

	if RDX.UI.Menu.IsOpen('default', 'rdx_extended', 'inventory') then
		RDX.ShowInventory()
	end
end)

RegisterNetEvent('rdx:removeInventoryItem')
AddEventHandler('rdx:removeInventoryItem', function(item, count, showNotification)
	for k,v in ipairs(RDX.PlayerData.inventory) do
		if v.name == item then
			RDX.UI.ShowInventoryItemNotification(false, v.label, v.count - count)
			RDX.PlayerData.inventory[k].count = count
			break
		end
	end

	if showNotification then
		RDX.UI.ShowInventoryItemNotification(false, item, count)
	end

	if RDX.UI.Menu.IsOpen('default', 'rdx_extended', 'inventory') then
		RDX.ShowInventory()
	end
end)

RegisterNetEvent('rdx:setJob')
AddEventHandler('rdx:setJob', function(job)
	RDX.PlayerData.job = job
end)

RegisterNetEvent('rdx:addWeapon')
AddEventHandler('rdx:addWeapon', function(weaponName, ammo)
	GiveWeaponToPed_2(PlayerPedId(), GetHashKey(weaponName), ammo, false, false, 0, false, 0.5, 1.0, 0, false, 0, false)
end)

RegisterNetEvent('rdx:addWeaponComponent')
AddEventHandler('rdx:addWeaponComponent', function(weaponName, weaponComponent)
	local componentHash = RDX.GetWeaponComponent(weaponName, weaponComponent).hash
	GiveWeaponComponentToEntity(PlayerPedId(), componentHash, GetHashKey(weaponName), true)
end)

RegisterNetEvent('rdx:setWeaponAmmo')
AddEventHandler('rdx:setWeaponAmmo', function(weaponName, weaponAmmo)
	SetPedAmmo(PlayerPedId(), GetHashKey(weaponName), weaponAmmo)
end)

-- 0.0: GOOD CONDITION 1.0: POOR CONDITION
RegisterNetEvent('rdx:setWeaponCondition')
AddEventHandler('rdx:setWeaponCondition', function(weaponName, level)
	SetWeaponCondition(GetHashKey(weaponName), level)
end)

RegisterNetEvent('rdx:setWeaponDirtLevel')
AddEventHandler('rdx:setWeaponDirtLevel', function(weaponName, level)
	SetWeaponDirtLevel(GetHashKey(weaponName), level, true) -- FIX: not sure what the last boolean is
end)

RegisterNetEvent('rdx:setWeaponMudLevel')
AddEventHandler('rdx:setWeaponMudLevel', function(weaponName, level)
	SetWeaponMudLevel(GetHashKey(weaponName), level, true) -- FIX: not sure what the last boolean is
end)

RegisterNetEvent('rdx:setWeaponRustLevel')
AddEventHandler('rdx:setWeaponRustLevel', function(weaponName, level)
	SetWeaponRustLevel(GetHashKey(weaponName), level, true) -- FIX: not sure what the last boolean is
end)

RegisterNetEvent('rdx:removeWeapon')
AddEventHandler('rdx:removeWeapon', function(weaponName)
	local playerPed = PlayerPedId()
	local weaponHash = GetHashKey(weaponName)

	RemoveWeaponFromPed(playerPed, weaponHash, true, Citizen.InvokeNative(0x5C2EA6C44F515F34, weaponHash))
	SetPedAmmo(playerPed, weaponHash, 0) -- remove leftover ammo
	SetAmmoInClip(playerPed, weaponHash, 0)
end)

RegisterNetEvent('rdx:removeWeaponComponent')
AddEventHandler('rdx:removeWeaponComponent', function(weaponName, weaponComponent)
	local componentHash = RDX.GetWeaponComponent(weaponName, weaponComponent).hash
	RemoveWeaponComponentFromPed(PlayerPedId(), componentHash, GetHashKey(weaponName))
end)

RegisterNetEvent('rdx:teleport')
AddEventHandler('rdx:teleport', function(coords)
	RDX.Game.Teleport(PlayerPedId(), coords)
end)

RegisterNetEvent('rdx:teleportWaypoint')
AddEventHandler('rdx:teleportWaypoint', function(coords)
	local x, y = table.unpack(GetWaypointCoords())
	RDX.Game.Teleport(PlayerPedId(), { x = x, y = y, z = -199.99 })
end)

RegisterNetEvent('rdx:setJob')
AddEventHandler('rdx:setJob', function(job)
	if Config.EnableHud then
		RDX.UI.HUD.UpdateElement('job', {
			job_label   = job.label,
			grade_label = job.grade_label
		})
	end
end)

RegisterNetEvent('rdx:spawnHorse')
AddEventHandler('rdx:spawnHorse', function(model)
	local _, horse = RDX.GetHorse(model)

	if (horse) then
		model = (type(model) == 'number' and model or GetHashKey(model))

		if IsModelInCdimage(model) then
			local playerPed = PlayerPedId()
			local playerCoords, playerHeading = GetEntityCoords(playerPed), GetEntityHeading(playerPed)

			RDX.Game.SpawnPed(model, playerCoords, playerHeading, function(ped)
				Citizen.InvokeNative(0x028F76B6E78246EB, playerPed, ped, -1, true)
			end)

			return
		end
	end

	TriggerEvent('chat:addMessage', {args = {'^1SYSTEM', 'Invalid horse model.'}})
end)

RegisterNetEvent('rdx:spawnVehicle')
AddEventHandler('rdx:spawnVehicle', function(vehicle)
	if IsModelInCdimage(vehicle) then
		local playerPed = PlayerPedId()
		local playerCoords, playerHeading = GetEntityCoords(playerPed), GetEntityHeading(playerPed)

		RDX.Game.SpawnVehicle(vehicle, playerCoords, playerHeading, function(vehicle)
			TaskWarpPedIntoVehicle(playerPed, vehicle, -1)
		end)
	else
		TriggerEvent('chat:addMessage', { args = { '^1SYSTEM', 'Invalid vehicle model.' } })
	end
end)

-- Removed drawing pickups here immediately and decided to add them to a table instead
-- Also made createMissingPickups use the other pickup function instead of having the
-- same code twice, further down we cull pickups when not needed

function AddPickup(pickupId, pickupLabel, pickupCoords, pickupType, pickupName, pickupComponents)
	pickups[pickupId] = {
		label = pickupLabel,
		textRange = false,
		coords = pickupCoords,
		type = pickupType,
		name = pickupName,
		components = pickupComponents,
		object = nil,
		deleteNow = false
	}
end

RegisterNetEvent('rdx:createPickup')
AddEventHandler('rdx:createPickup', function(pickupId, label, playerId, pickupType, name, components, isInfinity, pickupCoords)
    local playerPed, entityCoords, forward, objectCoords
    
    if isInfinity then
        objectCoords = pickupCoords
    else
        playerPed = GetPlayerPed(GetPlayerFromServerId(playerId))
        entityCoords = GetEntityCoords(playerPed)
        forward = GetEntityForwardVector(playerPed)
        objectCoords = (entityCoords + forward * 1.0)
    end

    AddPickup(pickupId, label, objectCoords, pickupType, name, components)
end)

RegisterNetEvent('rdx:createMissingPickups')
AddEventHandler('rdx:createMissingPickups', function(missingPickups)
	for pickupId, pickup in pairs(missingPickups) do
		AddPickup(pickupId, pickup.label, vec(pickup.coords.x, pickup.coords.y, pickup.coords.z), pickup.type, pickup.name, pickup.components, pickup.tintIndex)
	end
end)

RegisterNetEvent('rdx:registerSuggestions')
AddEventHandler('rdx:registerSuggestions', function(registeredCommands)
	for name,command in pairs(registeredCommands) do
		if command.suggestion then
			TriggerEvent('chat:addSuggestion', ('/%s'):format(name), command.suggestion.help, command.suggestion.arguments)
		end
	end
end)

RegisterNetEvent('rdx:removePickup')
AddEventHandler('rdx:removePickup', function(id)
	local pickup = pickups[id]
	if pickup and pickup.object then
		RDX.Game.DeleteObject(pickup.object)
		if pickup.type == 'item_weapon' then
			RemoveWeaponAsset(pickup.name)
		else
			SetModelAsNoLongerNeeded(Config.DefaultPickupModel)
		end
		pickup.deleteNow = true
	end
end)

RegisterNetEvent('rdx:deleteVehicle')
AddEventHandler('rdx:deleteVehicle', function(radius)
	local playerPed = PlayerPedId()

	if radius and tonumber(radius) then
		radius = tonumber(radius) + 0.01
		local vehicles = RDX.Game.GetVehiclesInArea(GetEntityCoords(playerPed), radius)

		for k,entity in ipairs(vehicles) do
			local attempt = 0

			while not NetworkHasControlOfEntity(entity) and attempt < 100 and DoesEntityExist(entity) do
				Wait(100)
				NetworkRequestControlOfEntity(entity)
				attempt = attempt + 1
			end

			if DoesEntityExist(entity) and NetworkHasControlOfEntity(entity) then
				RDX.Game.DeleteVehicle(entity)
			end
		end
	else
		local vehicle, attempt = RDX.Game.GetVehicleInDirection(), 0

		if IsPedInAnyVehicle(playerPed, true) then
			vehicle = GetVehiclePedIsIn(playerPed, false)
		end

		while not NetworkHasControlOfEntity(vehicle) and attempt < 100 and DoesEntityExist(vehicle) do
			Wait(100)
			NetworkRequestControlOfEntity(vehicle)
			attempt = attempt + 1
		end

		if DoesEntityExist(vehicle) and NetworkHasControlOfEntity(vehicle) then
			RDX.Game.DeleteVehicle(vehicle)
		end
	end
end)

RegisterNetEvent('rdx:deleteHorse')
AddEventHandler('rdx:deleteHorse', function()
	local playerPed = PlayerPedId()
	local horse, attempt = RDX.Game.GetHorseInDirection(), 0

	if IsPedOnMount(playerPed) then
		horse = GetMount(playerPed)
	end

	while not NetworkHasControlOfEntity(horse) and attempt < 100 and DoesEntityExist(horse) do
		Citizen.Wait(100)
		NetworkRequestControlOfEntity(horse)
		attempt = attempt + 1
	end

	if DoesEntityExist(horse) and NetworkHasControlOfEntity(horse) then
		RDX.Game.DeleteHorse(horse)
	end
end)

-- Pause menu disables HUD display
if Config.EnableHud then
	CreateThread(function()
		while true do
			Wait(300)

			if IsPauseMenuActive() and not isPaused then
				isPaused = true
				RDX.UI.HUD.SetDisplay(0.0)
			elseif not IsPauseMenuActive() and isPaused then
				isPaused = false
				RDX.UI.HUD.SetDisplay(1.0)
			end
		end
	end)
end

-- Keep track of ammo usage
CreateThread(function()
	while true do
		Wait(0)

		if isDead then
			Wait(500)
		else
			local playerPed = PlayerPedId()

			if IsPedShooting(playerPed) then
				local _, weaponHash = GetCurrentPedWeapon(playerPed, true)
				local weapon = RDX.GetWeaponFromHash(weaponHash)

				if weapon then
					local ammoCount = GetAmmoInPedWeapon(playerPed, weaponHash)
					TriggerServerEvent('rdx:updateWeaponAmmo', weapon.name, ammoCount)
				end
			end
		end
	end
end)

if Config.EnableInventoryKey then
	CreateThread(function()
		while true do
			Wait(0)

			if IsControlJustReleased(0, 0x1F6D95E5) then -- F4
				if IsInputDisabled(0) and not isDead and not RDX.UI.Menu.IsOpen('default', 'rdx_extended', 'inventory') then
					RDX.ShowInventory()
				end
			end
		end
	end)
end

-- Disable wanted level
if Config.DisableWantedLevel then
	-- Previous they were creating a contstantly running loop to check if the wanted level
	-- changed and then setting back to 0. This is all thats needed to disable a wanted level.
	SetMaxWantedLevel(0)
end

-- Pickups
CreateThread(function()
	while true do
		Wait(0)
		local playerPed = PlayerPedId()
		local playerCoords, letSleep = GetEntityCoords(playerPed), true
		-- For whatever reason there was a constant check to get the closest player here when it
		-- wasn't even being used
		
		-- Major refactor here, this culls the pickups if not within range.

		for pickupId, pickup in pairs(pickups) do
			local distance = #(playerCoords - pickup.coords)
			if pickup.deleteNow then
				pickup = nil
			else
				if distance < 50 then
					if not DoesEntityExist(pickup.object) then
						letSleep = false
						if pickup.type == 'item_weapon' then
							local weaponHash = GetHashKey(pickup.name)
							pickup.object = Citizen.InvokeNative(0x9888652B8BA77F73, weaponHash, 50, pickup.coords, true, 1.0, 0)

							for _, comp in ipairs(pickup.components) do
								local component = RDX.GetWeaponComponent(pickup.name, comp)
								GiveWeaponComponentToEntity(pickup.object, component.hash, weaponHash, true) -- FIX: last boolean unknown
							end
							
							SetEntityAsMissionEntity(pickup.object, true, false)
							PlaceObjectOnGroundProperly(pickup.object)
							SetEntityRotation(pickup.object, 90.0, 0.0, 0.0, 0.0, true) -- FIX: not sure what the last two parameters should be
							local model = GetEntityModel(pickup.object)
							local heightAbove = GetEntityHeightAboveGround(pickup.object)
							local currentCoords = GetEntityCoords(pickup.object)
							local modelDimensionMin, modelDimensionMax = GetModelDimensions(model)
							local size = (modelDimensionMax.y - modelDimensionMin.y) / 2
							SetEntityCoords(pickup.object, currentCoords.x, currentCoords.y, (currentCoords.z - heightAbove) + size)
						else
							RDX.Game.SpawnLocalObject(Config.DefaultPickupModel, pickup.coords, function(obj)
								pickup.object = obj
							end)

							while not pickup.object do
								Wait(10)
							end
							
							SetEntityAsMissionEntity(pickup.object, true, false)
							PlaceObjectOnGroundProperly(pickup.object)
						end

						FreezeEntityPosition(pickup.object, true)
						SetEntityCollision(pickup.object, false, true)
					end
				else
					if DoesEntityExist(pickup.object) then
						DeleteObject(pickup.object)
						if pickup.type == 'item_weapon' then
							RemoveWeaponAsset(pickup.name)
						else
							SetModelAsNoLongerNeeded(Config.DefaultPickupModel)
						end
					end
				end
				
				if distance < 5 then
					local label = pickup.label
					letSleep = false

					if distance < 1 then
						if IsControlJustReleased(0, 0xCEFD9220) then
							-- Removed the closestDistance check here, not needed
							if IsPedOnFoot(playerPed) and not pickup.textRange then
								pickup.textRange = true

								-- FIX: unknown anim atm
								--local dict, anim = 'weapons@first_person@aim_rng@generic@projectile@sticky_bomb@', 'plant_floor'
								-- Lets use our new function instead of manually doing it
								--RDX.Game.PlayAnim(dict, anim, true, 1000)
								--Wait(1000)

								TriggerServerEvent('rdx:onPickup', pickupId)
								--PlaySoundFrontend(-1, 'PICK_UP', 'HUD_FRONTEND_DEFAULT_SOUNDSET', false)
							end
						end

						label = ('%s~n~%s'):format(label, _U('standard_pickup_prompt'))
					end
					
					local pickupCoords = GetEntityCoords(pickup.object)
					RDX.Game.Utils.DrawText3D(vec(pickupCoords.x, pickupCoords.y, pickupCoords.z + 0.25), label, 1.2, 1)
				elseif pickup.textRange then
					pickup.textRange = false
				end
			end
		end

		if letSleep then
			Wait(500)
		end
	end
end)

-- Update current player coords
CreateThread(function()
	-- wait for player to restore coords
	while not isLoadoutLoaded do
		Wait(1000)
	end
	
	local previousCoords = vector3(RDX.PlayerData.coords.x, RDX.PlayerData.coords.y, RDX.PlayerData.coords.z)
	local playerHeading = RDX.PlayerData.heading
	local formattedCoords = {x = RDX.Math.Round(previousCoords.x, 1), y = RDX.Math.Round(previousCoords.y, 1), z = RDX.Math.Round(previousCoords.z, 1), heading = playerHeading}

	while true do
		-- update the players position every second instead of a configed amount otherwise
		-- serverside won't catch up
		Wait(1000)
		local playerPed = PlayerPedId()
		local playerCoords = GetEntityCoords(playerPed)
		local distance = #(playerCoords - previousCoords)

		if distance > 10 then
			previousCoords = playerCoords
			playerHeading = RDX.Math.Round(GetEntityHeading(playerPed), 1)
			formattedCoords = {x = RDX.Math.Round(playerCoords.x, 1), y = RDX.Math.Round(playerCoords.y, 1), z = RDX.Math.Round(playerCoords.z, 1), heading = playerHeading}
			TriggerServerEvent('rdx:updateCoords', formattedCoords)
		end
	end
end)
