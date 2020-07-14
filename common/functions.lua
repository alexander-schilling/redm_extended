local Charset = {}

for i = 48,  57 do table.insert(Charset, string.char(i)) end
for i = 65,  90 do table.insert(Charset, string.char(i)) end
for i = 97, 122 do table.insert(Charset, string.char(i)) end

RDX.GetRandomString = function(length)
	math.randomseed(GetGameTimer())

	if length > 0 then
		return RDX.GetRandomString(length - 1) .. Charset[math.random(1, #Charset)]
	else
		return ''
	end
end

RDX.GetConfig = function()
	return Config
end

RDX.GetWeapon = function(weaponName)
	weaponName = string.upper(weaponName)

	for k,v in ipairs(Config.Weapons) do
		if v.name == weaponName then
			return k, v
		end
	end
end

RDX.GetWeaponFromHash = function(weaponHash)
	for k,v in ipairs(Config.Weapons) do
		if GetHashKey(v.name) == weaponHash then
			return v
		end
	end
end

RDX.GetWeaponList = function()
	return Config.Weapons
end

RDX.GetWeaponLabel = function(weaponName)
	weaponName = string.upper(weaponName)

	for k,v in ipairs(Config.Weapons) do
		if v.name == weaponName then
			return v.label
		end
	end
end

RDX.GetWeaponComponent = function(weaponName, weaponComponent)
	weaponName = string.upper(weaponName)

	for k,v in ipairs(Config.Weapons) do
		if v.name == weaponName then
			for k2,v2 in ipairs(v.components) do
				if v2.name == weaponComponent then
					return v2
				end
			end
		end
	end
end

RDX.GetHorse = function(horseName)
	horseName = string.lower(horseName)

	for i = 1, #Config.Horses do
		local horse = Config.Horses[i]

		if (string.lower(horse.name) == horseName or string.lower(horse.short) == horseName) then
			return i, horse
		end
	end
end

RDX.GetHorseFromHash = function(horseHash)
	for i = 1, #Config.Horses do
		local horse = Config.Horses[i]

		if (GetHashKey(horse.name) == horseHash) then
			return horse
		end
	end
end

RDX.GetHorseList = function()
	return Config.Horses
end

RDX.GetAccount = function(accountName)
	accountName = string.lower(accountName or 'unknown')

	for i = 1, #Config.Accounts do
		local account = Config.Accounts[i]

		if (string.lower(account.name) == accountName) then
			return i, account
		end
	end
end

RDX.GetAccountLabel = function(accountName)
	local index, account = RDX.GetAccount(accountName)

	if (account ~= nil) then
		return account.label
	end
end

RDX.DumpTable = function(table, nb)
	if nb == nil then
		nb = 0
	end

	if type(table) == 'table' then
		local s = ''
		for i = 1, nb + 1, 1 do
			s = s .. "    "
		end

		s = '{\n'
		for k,v in pairs(table) do
			if type(k) ~= 'number' then k = '"'..k..'"' end
			for i = 1, nb, 1 do
				s = s .. "    "
			end
			s = s .. '['..k..'] = ' .. RDX.DumpTable(v, nb + 1) .. ',\n'
		end

		for i = 1, nb, 1 do
			s = s .. "    "
		end

		return s .. '}'
	else
		return tostring(table)
	end
end

RDX.Round = function(value, numDecimalPlaces)
	return RDX.Math.Round(value, numDecimalPlaces)
end
