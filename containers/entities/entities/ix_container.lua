
ENT.Type = "anim"
ENT.PrintName = "Container"
ENT.Category = "Helix"
ENT.Spawnable = false
ENT.bNoPersist = true

function ENT:SetupDataTables()
	self:NetworkVar("Int", 0, "ID")
	self:NetworkVar("Bool", 0, "Locked")
	self:NetworkVar("String", 0, "DisplayName")
end

if (SERVER) then
	function ENT:Initialize()
		self:PhysicsInit(SOLID_VPHYSICS)
		self:SetSolid(SOLID_VPHYSICS)
		self:SetUseType(SIMPLE_USE)
		self.receivers = {}
		self:PrecacheGibs()

		local definition = ix.container.stored[self:GetModel():lower()]

		if (definition) then
			self:SetDisplayName(definition.name)
		end

		if (definition.breakable) then
			self:SetHealth(definition.health)
		end

		local physObj = self:GetPhysicsObject()

		if (IsValid(physObj)) then
			physObj:EnableMotion(true)
			physObj:Wake()
		end
	end

	function ENT:OnTakeDamage(dmgInfo)
		local definition = ix.container.stored[self:GetModel():lower()]
		if (definition.breakable) then
			self:SetHealth(self:Health() - dmgInfo:GetDamage())

			if (self:Health() <= 0) then
				self:GibBreakServer(Vector(0, 0, 0))
				self:EmitSound(table.Random(definition.breaksounds), 70, 100, 1, CHAN_AUTO)
				local radius = 50 -- Effect radius
				local force = 200 -- Force magnitude

				local entities = ents.FindInSphere(self:GetPos(), radius)
				for _, ent in ipairs(entities) do
					if ent:GetClass() == "prop_physics" then -- Check if the entity is a physics prop
						local phys = ent:GetPhysicsObject()
						if IsValid(phys) then
							local dir = (ent:GetPos() - self:GetPos()):GetNormalized() -- Direction from self to the entity
							phys:ApplyForceCenter(dir * force)
						end
					end
				end
				self:Remove()
				self:Break()
			end
		end
    end

	function ENT:SetInventory(inventory)
		if (inventory) then
			self:SetID(inventory:GetID())
		end
	end

	function ENT:Break()
		local index = self:GetID()

		if (!ix.shuttingDown and !self.ixIsSafe and ix.entityDataLoaded and index) then
			local inventory = ix.item.inventories[index]
	
			if (inventory) then
				-- Correctly iterate over all items in the inventory
				for _, item in pairs(inventory:GetItems()) do
					local curInv = ix.item.inventories[item.invID or 0]
					-- Ensure 'item' is treated as an item object
					if (item) then
						if self:GetModel() == "models/Items/item_item_crate.mdl" then
							item:Spawn( self:GetPos() + (self:GetForward() * math.Rand(self:OBBMins(), self:OBBMaxs())) + self:GetRight() * math.Rand(self:OBBMins(), self:OBBMaxs()) + self:GetUp() * (self:OBBMaxs()/2), self:GetAngles())
						else
							item:Spawn(self:GetPos() + (self:GetForward() * math.Rand(self:OBBMins(), self:OBBMaxs())) + self:GetRight() * math.Rand(self:OBBMins(), self:OBBMaxs()), self:GetAngles())
						end

						-- we are transferring this item from an inventory to the world
						item.invID = 0

						curInv:Remove(item.id, false, true)

						local query = mysql:Update("ix_items")
							query:Update("inventory_id", 0)
							query:Where("item_id", item.id)
						query:Execute()

						inventory = ix.item.inventories[0]
						inventory[item:GetID()] = item

						if (item.OnTransferred) then
							item:OnTransferred(curInv, inventory)
						end
					end
					hook.Run("OnItemTransferred", item, curInv, inventory)
				end
			end
		end
	end

	function ENT:OnRemove()
		local index = self:GetID()

		if (!ix.shuttingDown and !self.ixIsSafe and ix.entityDataLoaded and index) then
			local inventory = ix.item.inventories[index]

			if (inventory) then
				ix.item.inventories[index] = nil

				local query = mysql:Delete("ix_items")
					query:Where("inventory_id", index)
				query:Execute()

				query = mysql:Delete("ix_inventories")
					query:Where("inventory_id", index)
				query:Execute()

				hook.Run("ContainerRemoved", self, inventory)
			end
		end
	end

	function ENT:OpenInventory(activator)
		local inventory = self:GetInventory()

		if (inventory) then
			local name = self:GetDisplayName()

			ix.storage.Open(activator, inventory, {
				name = name,
				entity = self,
				searchTime = ix.config.Get("containerOpenTime", 0.7),
				OnPlayerClose = function()
					ix.log.Add(activator, "closeContainer", name, inventory:GetID())
				end
			})

			if (self:GetLocked()) then
				self.Sessions[activator:GetCharacter():GetID()] = true
			end

			ix.log.Add(activator, "openContainer", name, inventory:GetID())
		end
	end

	function ENT:Use(activator)
		local inventory = self:GetInventory()

		if (inventory and (activator.ixNextOpen or 0) < CurTime()) then
			local character = activator:GetCharacter()

			if (character) then
				local def = ix.container.stored[self:GetModel():lower()]

				if (self:GetLocked() and !self.Sessions[character:GetID()]) then
					self:EmitSound(def.locksound or "doors/default_locked.wav")

					if (!self.keypad) then
						net.Start("ixContainerPassword")
							net.WriteEntity(self)
						net.Send(activator)
					end
				else
					self:OpenInventory(activator)
				end
			end

			activator.ixNextOpen = CurTime() + 1
		end
	end
else
	ENT.PopulateEntityInfo = true

	local COLOR_LOCKED = Color(200, 38, 19, 200)
	local COLOR_UNLOCKED = Color(135, 211, 124, 200)

	function ENT:OnPopulateEntityInfo(tooltip)
		local definition = ix.container.stored[self:GetModel():lower()]
		local bLocked = self:GetLocked()

		surface.SetFont("ixIconsSmall")

		local iconText = bLocked and "P" or "Q"
		local iconWidth, iconHeight = surface.GetTextSize(iconText)

		-- minimal tooltips have centered text so we'll draw the icon above the name instead
		if (tooltip:IsMinimal()) then
			local icon = tooltip:AddRow("icon")
			icon:SetFont("ixIconsSmall")
			icon:SetTextColor(bLocked and COLOR_LOCKED or COLOR_UNLOCKED)
			icon:SetText(iconText)
			icon:SizeToContents()
		end

		local title = tooltip:AddRow("name")
		title:SetImportant()
		title:SetText(self:GetDisplayName())
		title:SetBackgroundColor(ix.config.Get("color"))
		title:SetTextInset(iconWidth + 8, 0)
		title:SizeToContents()

		if (!tooltip:IsMinimal()) then
			title.Paint = function(panel, width, height)
				panel:PaintBackground(width, height)

				surface.SetFont("ixIconsSmall")
				surface.SetTextColor(bLocked and COLOR_LOCKED or COLOR_UNLOCKED)
				surface.SetTextPos(4, height * 0.5 - iconHeight * 0.5)
				surface.DrawText(iconText)
			end
		end

		local description = tooltip:AddRow("description")
		description:SetText(definition.description)
		description:SizeToContents()
	end
end

function ENT:GetInventory()
	return ix.item.inventories[self:GetID()]
end
