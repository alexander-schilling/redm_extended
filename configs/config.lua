Config = {}
Config.Locale = 'en'

Config.Accounts = {
	['bank'] = { label = _U('account_bank'), priority = 0 },
	['gold'] = { label = _U('account_gold'), priority = 1 },
	['money'] = { label = _U('account_money'), priority = 2 }
}

Config.StartingAccountMoney = { money = 3, bank = 5 }
Config.DefaultSpawnPosition = {x = -163.48, y = 633.58, z = 114.03, heading = 233.63}

Config.EnableSocietyPayouts = false -- pay from the society account that the player is employed at? Requirement: esx_society
Config.EnableHud            = true -- enable the default hud? Display current job and accounts (black, bank & cash)
Config.EnableInventoryKey 	= false
Config.MaxWeight            = 124   -- the max inventory weight without backpack
Config.PaycheckInterval     = 30 * 60000 -- how often to recieve pay checks in milliseconds
Config.EnableDebug          = false
Config.PrimaryIdentifier	= 'steam' -- Options: `steam`, `license`, `fivem`, `discord`, `xbl`, `live` and `ip`, default `license`

Config.DefaultPlayerModel = `mp_male`
Config.DefaultPickupModel = `s_mp_moneybag02x`
