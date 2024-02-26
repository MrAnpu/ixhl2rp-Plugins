--[[
	ix.container.Register(model, {
		name = "Crate",
		description = "A simple wooden create.",
		width = 4,
		height = 4,
		breakable = true,
		health = 100,
		breaksounds = {
			"sound_path",
		},
		locksound = "",
		opensound = ""
	})
]]--

ix.container.Register("models/props_junk/wood_crate001a.mdl", {
	name = "Crate",
	description = "A simple wooden crate.",
	width = 6,
	height = 6,
	breakable = true,
	health = 100,
	breaksounds = {
		"physics/wood/wood_plank_break2.wav",
		"physics/wood/wood_plank_break3.wav",
		"physics/wood/wood_plank_break4.wav",
	},
})

ix.container.Register("models/props_c17/lockers001a.mdl", {
	name = "Locker",
	description = "A white locker.",
	width = 4,
	height = 6,
	breakable = false
})

ix.container.Register("models/props_wasteland/controlroom_storagecloset001a.mdl", {
	name = "Metal Cabinet",
	description = "A green metal cabinet.",
	width = 6,
	height = 8,
	breakable = false
})

ix.container.Register("models/props_wasteland/controlroom_storagecloset001b.mdl", {
	name = "Metal Cabinet",
	description = "A green metal cabinet.",
	width = 6,
	height = 8,
	breakable = false
})

ix.container.Register("models/props_wasteland/controlroom_filecabinet001a.mdl", {
	name = "File Cabinet",
	description = "A metal filing cabinet.",
	width = 5,
	height = 3,
	breakable = false
})

ix.container.Register("models/props_wasteland/controlroom_filecabinet002a.mdl", {
	name = "File Cabinet",
	description = "A metal filing cabinet.",
	width = 4,
	height = 5,
	breakable = false
})

ix.container.Register("models/props_lab/filecabinet02.mdl", {
	name = "File Cabinet",
	description = "A metal filing cabinet.",
	width = 5,
	height = 6,
	breakable = false
})

ix.container.Register("models/props_c17/furniturefridge001a.mdl", {
	name = "Refrigerator",
	description = "A metal box for keeping food in.",
	width = 5,
	height = 6,
	breakable = false
})

ix.container.Register("models/props_wasteland/kitchen_fridge001a.mdl", {
	name = "Large Refrigerator",
	description = "A large metal box for storing even more food in.",
	width = 10,
	height = 15,
	breakable = false
})

ix.container.Register("models/props_junk/trashbin01a.mdl", {
	name = "Trash Bin",
	description = "What do you expect to find in here?",
	width = 4,
	height = 6,
	breakable = false
})

ix.container.Register("models/props_junk/trashdumpster01a.mdl", {
	name = "Dumpster",
	description = "A dumpster meant to stow away trash. It emanates an unpleasant smell.",
	width = 6,
	height = 5,
	breakable = false
})

ix.container.Register("models/items/ammocrate_smg1.mdl", {
	name = "Ammo Crate",
	description = "A heavy crate that stores ammo.",
	width = 8,
	height = 6,
	breakable = false,
	OnOpen = function(entity, activator)
		local closeSeq = entity:LookupSequence("Close")
		entity:ResetSequence(closeSeq)

		timer.Simple(2, function()
			if (entity and IsValid(entity)) then
				local openSeq = entity:LookupSequence("Open")
				entity:ResetSequence(openSeq)
			end
		end)
	end
})

ix.container.Register("models/props_forest/footlocker01_closed.mdl", {
	name = "Footlocker",
	description = "A small chest to store belongings in.",
	width = 7,
	height = 5,
	breakable = false,
})

ix.container.Register("models/Items/item_item_crate.mdl", {
	name = "Supply Crate",
	description = "A crate to store supplys in.",
	width = 6,
	height = 5,
	breakable = true,
	health = 100,
	breaksounds = {
		"physics/wood/wood_plank_break2.wav",
		"physics/wood/wood_plank_break3.wav",
		"physics/wood/wood_plank_break4.wav",
	},
})

ix.container.Register("models/props_c17/cashregister01a.mdl", {
	name = "Cash Register",
	description = "A register with some buttons and a drawer.",
	width = 3,
	height = 2,
	breakable = false
})
