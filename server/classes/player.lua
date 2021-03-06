function CreateExtendedPlayer(playerId, identifier, characterId, userData)
	local self = {}

	self.playerId = playerId
	self.source = playerId
	self.identifier = identifier
	self.characterId = characterId
	self.uniqueId = userData.uniqueId
	self.vipLevel = userData.vipLevel
	self.group = userData.group

	self.accounts = userData.accounts
	self.coords = userData.coords
	self.inventory = userData.inventory
	self.job = userData.job
	self.loadout = userData.loadout
	self.name = userData.playerName
	self.variables = {}
	self.weight = userData.weight
	self.maxWeight = Config.MaxWeight

	ExecuteCommand(('add_principal identifier.%s group.%s'):format(self.identifier, self.group))

	self.triggerEvent = function(eventName, ...)
		TriggerClientEvent(eventName, self.source, ...)
	end

	self.setCoords = function(coords)
		self.updateCoords(coords)
		self.triggerEvent('rdx:teleport', coords)
	end

	self.updateCoords = function(coords)
		self.coords = {x = RDX.Math.Round(coords.x, 1), y = RDX.Math.Round(coords.y, 1), z = RDX.Math.Round(coords.z, 1), heading = RDX.Math.Round(coords.heading or 0.0, 1)}
	end

	self.getCoords = function(vector)
		if vector then
			return vector3(self.coords.x, self.coords.y, self.coords.z)
		else
			return self.coords
		end
	end

	self.kick = function(reason)
		DropPlayer(self.source, reason)
	end

	self.setMoney = function(money, recursion)
		money = RDX.Math.Round(money)
		self.setAccountMoney('money', money)

		if(not recursion)then
			TriggerEvent("es:getPlayerFromId", self.source, function(user) user.setMoney(money) end)
		end
	end

	self.getBank = function()
		return self.getAccount('bank').money
	end

	self.removeBank = function(money)
		self.removeAccountMoney('bank', money)
	end

	self.addBank = function(money)
		self.addAccountMoney('bank', money)
	end

	self.getMoney = function()
		return self.getAccount('money').money
	end

	self.addMoney = function(money, recursion)
		money = RDX.Math.Round(money)
		self.addAccountMoney('money', money)

		if(not recursion)then
			TriggerEvent("es:getPlayerFromId", self.source, function(user) user.addMoney(money, true) end)
		end
	end

	self.removeMoney = function(money, recursion)
		if(not recursion)then
			TriggerEvent("es:getPlayerFromId", self.source, function(user) user.removeMoney(money, true) end)
		end

		money = RDX.Math.Round(money)
		self.removeAccountMoney('money', money)
	end

	self.getIdentifier = function()
		return self.identifier
	end

	self.getCharacterId = function()
		return self.characterId
	end

	self.getUniqueId = function()
		return self.uniqueId
	end

	self.setVipLevel = function(newVipLevel)
		self.vipLevel = newVipLevel

		TriggerEvent('rdx:setVipLevel', self.source, self.vipLevel)
		self.triggerEvent('rdx:setVipLevel', self.vipLevel)

		MySQL.Async.execute('UPDATE users SET vip_level = @vip_level WHERE `identifier` = @identifier', {
			['@vip_level'] = self.vipLevel,
			['@identifier'] = self.getIdentifier()
		})
	end

	self.getVipLevel = function()
		return self.group
	end

	self.setGroup = function(newGroup, recursion)
		if(not recursion)then
			TriggerEvent("es:getPlayerFromId", self.source, function(user) user.set("group", newGroup) end)
		end

		ExecuteCommand(('remove_principal identifier.%s group.%s'):format(self.identifier, self.group))
		self.group = newGroup
		ExecuteCommand(('add_principal identifier.%s group.%s'):format(self.identifier, self.group))

		MySQL.Async.execute('UPDATE users SET `group` = @group WHERE `identifier` = @identifier', {
			['@group'] = self.group,
			['@identifier'] = self.getIdentifier()
		})
	end

	self.getGroup = function()
		return self.group
	end

	self.set = function(k, v, recursion)
		if(not recursion)then
			TriggerEvent("es:getPlayerFromId", self.source, function(user) if(user)then user.set(k, v) end end)
		end

		self.variables[k] = v
	end

	self.get = function(k)
		return self.variables[k]
	end

	self.getAccounts = function(minimal)
		if minimal then
			local minimalAccounts = {}

			for k,v in ipairs(self.accounts) do
				minimalAccounts[v.name] = v.money
			end

			return minimalAccounts
		else
			return self.accounts
		end
	end

	self.getAccount = function(account)
		for k,v in ipairs(self.accounts) do
			if v.name == account then
				return v
			end
		end
	end

	self.getInventory = function(minimal)
		if minimal then
			local minimalInventory = {}

			for k,v in ipairs(self.inventory) do
				if v.count > 0 then
					minimalInventory[v.name] = v.count
				end
			end

			return minimalInventory
		else
			return self.inventory
		end
	end

	self.getJob = function()
		return self.job
	end

	self.getLoadout = function(minimal)
		if minimal then
			local minimalLoadout = {}

			for k,v in ipairs(self.loadout) do
				minimalLoadout[v.name] = {ammo = v.ammo}
				if v.tintIndex > 0 then minimalLoadout[v.name].tintIndex = v.tintIndex end

				if #v.components > 0 then
					local components = {}

					for k2,component in ipairs(v.components) do
						if component ~= 'clip_default' then
							table.insert(components, component)
						end
					end

					if #components > 0 then
						minimalLoadout[v.name].components = components
					end
				end
			end

			return minimalLoadout
		else
			return self.loadout
		end
	end

	self.getName = function()
		return self.name
	end

	self.setName = function(newName)
		self.name = newName
	end

	self.setAccountMoney = function(accountName, money)
		if money >= 0 then
			local account = self.getAccount(accountName)

			if account then
				local prevMoney = account.money
				local newMoney = RDX.Math.Round(money)
				account.money = newMoney

				self.triggerEvent('rdx:setAccountMoney', account)
			end
		end
	end

	self.addAccountMoney = function(accountName, money)
		if money > 0 then
			local account = self.getAccount(accountName)

			if account then
				local newMoney = account.money + RDX.Math.Round(money)
				account.money = newMoney

				self.triggerEvent('rdx:setAccountMoney', account)
			end
		end
	end

	self.removeAccountMoney = function(accountName, money)
		if money > 0 then
			local account = self.getAccount(accountName)

			if account then
				local newMoney = account.money - RDX.Math.Round(money)
				account.money = newMoney

				self.triggerEvent('rdx:setAccountMoney', account)
			end
		end
	end

	self.getInventoryItem = function(name)
		local found = false
		local newItem

		for k,v in ipairs(self.inventory) do
			if v.name == name then
				found = true
				return v
			end
		end

		-- Ran only if the item wasn't found in your inventory
		local item = RDX.Items[name]

		-- if item exists -> run
		if(item)then
			-- Create new item
			newItem = {
				name = name,
				count = 0,
				label = item.label,
				weight = item.weight,
				limit = item.limit,
				usable = RDX.UsableItemsCallbacks[name] ~= nil,
				rare = item.rare,
				canRemove = item.canRemove
			}

			-- Insert into players inventory
			table.insert(self.inventory, newItem)

			-- Return the item that was just added
			return newItem
		end

		return
	end

	self.addInventoryItem = function(name, count)
		local item = self.getInventoryItem(name)

		if item then
			count = RDX.Math.Round(count)
			item.count = item.count + count
			self.weight = self.weight + (item.weight * count)

			TriggerEvent('rdx:onAddInventoryItem', self.source, item.name, item.count)
			self.triggerEvent('rdx:addInventoryItem', item.name, item.count, false, item)
		end
	end

	self.removeInventoryItem = function(name, count)
		local item = self.getInventoryItem(name)

		if item then
			count = RDX.Math.Round(count)
			local newCount = item.count - count

			if newCount >= 0 then
				item.count = newCount
				self.weight = self.weight - (item.weight * count)

				TriggerEvent('rdx:onRemoveInventoryItem', self.source, item.name, item.count)
				self.triggerEvent('rdx:removeInventoryItem', item.name, item.count)
			end
		end
	end

	self.setInventoryItem = function(name, count)
		local item = self.getInventoryItem(name)

		if item and count >= 0 then
			count = RDX.Math.Round(count)

			if count > item.count then
				self.addInventoryItem(item.name, count - item.count)
			else
				self.removeInventoryItem(item.name, item.count - count)
			end
		end
	end

	self.getWeight = function()
		return self.weight
	end

	self.getMaxWeight = function()
		return self.maxWeight
	end

	self.canCarryItem = function(name, count)
		local currentWeight, itemWeight = self.weight, RDX.Items[name].weight
		local newWeight = currentWeight + (itemWeight * count)
		local inventoryitem = self.getInventoryItem(name)
		
		if RDX.Items[name].limit ~= nil and RDX.Items[name].limit ~= -1 then
			if count > RDX.Items[name].limit then
				return false
			elseif (inventoryitem.count + count) > RDX.Items[name].limit then
				return false
			end
		end
		return newWeight <= self.maxWeight
	end

	self.canSwapItem = function(firstItem, firstItemCount, testItem, testItemCount)
		local firstItemObject = self.getInventoryItem(firstItem)
		local testItemObject = self.getInventoryItem(testItem)

		if firstItemObject.count >= firstItemCount then
			local weightWithoutFirstItem = RDX.Math.Round(self.weight - (firstItemObject.weight * firstItemCount))
			local weightWithTestItem = RDX.Math.Round(weightWithoutFirstItem + (testItemObject.weight * testItemCount))

			return weightWithTestItem <= self.maxWeight
		end

		return false
	end

	self.setMaxWeight = function(newWeight)
		self.maxWeight = newWeight
		self.triggerEvent('rdx:setMaxWeight', self.maxWeight)
	end

	self.setJob = function(job, grade)
		grade = tostring(grade)
		local lastJob = json.decode(json.encode(self.job))

		if RDX.DoesJobExist(job, grade) then
			local jobObject, gradeObject = RDX.Jobs[job], RDX.Jobs[job].grades[grade]

			self.job.id    = jobObject.id
			self.job.name  = jobObject.name
			self.job.label = jobObject.label

			self.job.grade        = tonumber(grade)
			self.job.grade_name   = gradeObject.name
			self.job.grade_label  = gradeObject.label
			self.job.grade_salary = gradeObject.salary

			if gradeObject.skin_male then
				self.job.skin_male = json.decode(gradeObject.skin_male)
			else
				self.job.skin_male = {}
			end

			if gradeObject.skin_female then
				self.job.skin_female = json.decode(gradeObject.skin_female)
			else
				self.job.skin_female = {}
			end

			TriggerEvent('rdx:setJob', self.source, self.job, lastJob)
			self.triggerEvent('rdx:setJob', self.job)
		else
			print(('[RDX] [^3WARNING^7] Ignoring invalid .setJob() usage for "%s"'):format(self.identifier))
		end
	end

	self.addWeapon = function(weaponName, ammo)
		if not self.hasWeapon(weaponName) then
			local weaponLabel = RDX.GetWeaponLabel(weaponName)

			table.insert(self.loadout, {
				name = weaponName,
				ammo = ammo,
				label = weaponLabel,
				components = {},
				tintIndex = 0
			})

			self.triggerEvent('rdx:addWeapon', weaponName, 0) -- prevent duplicate ammo
			self.triggerEvent('rdx:setWeaponAmmo', weaponName, ammo)
			self.triggerEvent('rdx:addInventoryItem', weaponLabel, false, true)
		end
	end

	self.addWeaponComponent = function(weaponName, weaponComponent)
		local loadoutNum, weapon = self.getWeapon(weaponName)

		if weapon then
			local component = RDX.GetWeaponComponent(weaponName, weaponComponent)

			if component then
				if not self.hasWeaponComponent(weaponName, weaponComponent) then
					table.insert(self.loadout[loadoutNum].components, weaponComponent)
					self.triggerEvent('rdx:addWeaponComponent', weaponName, weaponComponent)
					self.triggerEvent('rdx:addInventoryItem', component.label, false, true)
				end
			end
		end
	end

	self.addWeaponAmmo = function(weaponName, ammoCount)
		local loadoutNum, weapon = self.getWeapon(weaponName)

		if weapon then
			weapon.ammo = weapon.ammo + ammoCount
			self.triggerEvent('rdx:setWeaponAmmo', weaponName, weapon.ammo)
		end
	end

	self.updateWeaponAmmo = function(weaponName, ammoCount)
		local loadoutNum, weapon = self.getWeapon(weaponName)

		if weapon then
			if ammoCount < weapon.ammo then
				weapon.ammo = ammoCount
			end
		end
	end

	self.setWeaponTint = function(weaponName, weaponTintIndex)
		local loadoutNum, weapon = self.getWeapon(weaponName)

		if weapon then
			local weaponNum, weaponObject = RDX.GetWeapon(weaponName)

			if weaponObject.tints and weaponObject.tints[weaponTintIndex] then
				self.loadout[loadoutNum].tintIndex = weaponTintIndex
				self.triggerEvent('rdx:setWeaponTint', weaponName, weaponTintIndex)
				self.triggerEvent('rdx:addInventoryItem', weaponObject.tints[weaponTintIndex], false, true)
			end
		end
	end

	self.getWeaponTint = function(weaponName)
		local loadoutNum, weapon = self.getWeapon(weaponName)

		if weapon then
			return weapon.tintIndex
		end

		return 0
	end

	self.removeWeapon = function(weaponName)
		local weaponLabel

		for k,v in ipairs(self.loadout) do
			if v.name == weaponName then
				weaponLabel = v.label

				for k2,v2 in ipairs(v.components) do
					self.removeWeaponComponent(weaponName, v2)
				end

				table.remove(self.loadout, k)
				break
			end
		end

		if weaponLabel then
			self.triggerEvent('rdx:removeWeapon', weaponName)
			self.triggerEvent('rdx:removeInventoryItem', weaponLabel, false, true)
		end
	end

	self.removeWeaponComponent = function(weaponName, weaponComponent)
		local loadoutNum, weapon = self.getWeapon(weaponName)

		if weapon then
			local component = RDX.GetWeaponComponent(weaponName, weaponComponent)

			if component then
				if self.hasWeaponComponent(weaponName, weaponComponent) then
					for k,v in ipairs(self.loadout[loadoutNum].components) do
						if v == weaponComponent then
							table.remove(self.loadout[loadoutNum].components, k)
							break
						end
					end

					self.triggerEvent('rdx:removeWeaponComponent', weaponName, weaponComponent)
					self.triggerEvent('rdx:removeInventoryItem', component.label, false, true)
				end
			end
		end
	end

	self.removeWeaponAmmo = function(weaponName, ammoCount)
		local loadoutNum, weapon = self.getWeapon(weaponName)

		if weapon then
			weapon.ammo = weapon.ammo - ammoCount
			self.triggerEvent('rdx:setWeaponAmmo', weaponName, weapon.ammo)
		end
	end

	self.hasWeaponComponent = function(weaponName, weaponComponent)
		local loadoutNum, weapon = self.getWeapon(weaponName)

		if weapon then
			for k,v in ipairs(weapon.components) do
				if v == weaponComponent then
					return true
				end
			end

			return false
		else
			return false
		end
	end

	self.hasWeapon = function(weaponName)
		for k,v in ipairs(self.loadout) do
			if v.name == weaponName then
				return true
			end
		end

		return false
	end

	self.getWeapon = function(weaponName)
		for k,v in ipairs(self.loadout) do
			if v.name == weaponName then
				return k, v
			end
		end

		return
	end

	self.showNotification = function(msg, flash, saveToBrief, hudColorIndex)
		self.triggerEvent('rdx:showNotification', msg, flash, saveToBrief, hudColorIndex)
	end

	self.showHelpNotification = function(msg, thisFrame, beep, duration)
		self.triggerEvent('rdx:showHelpNotification', msg, thisFrame, beep, duration)
	end

	return self
end
