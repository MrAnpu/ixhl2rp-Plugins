
AddCSLuaFile()

if (CLIENT) then
	SWEP.PrintName = "Hands"
	SWEP.Slot = 0
	SWEP.SlotPos = 1
	SWEP.DrawAmmo = false
	SWEP.DrawCrosshair = true
end

SWEP.Author = "Chessnut"
SWEP.Instructions = [[Primary Fire: Throw/Punch
Secondary Fire: Knock/Pickup
Secondary Fire + Mouse: Rotate Object
Secondary Fire + Reload: Put your hands up
Reload: Drop]]
SWEP.Purpose = "Hitting things and knocking on doors."
SWEP.Drop = false
SWEP.Spawnable = true
SWEP.AdminOnly = true

SWEP.ViewModelFOV = 45
SWEP.ViewModelFlip = false
SWEP.AnimPrefix	 = "rpg"

SWEP.ViewTranslation = 4
if CLIENT then
	SWEP.NextAllowedPlayRateChange = 0
end

SWEP.Primary.ClipSize = -1
SWEP.Primary.DefaultClip = -1
SWEP.Primary.Automatic = false
SWEP.Primary.Ammo = ""
SWEP.Primary.Damage = 5
SWEP.Primary.Delay = 0.75

SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = 0
SWEP.Secondary.Automatic = false
SWEP.Secondary.Ammo = ""
SWEP.Secondary.Delay = 0.5

SWEP.ViewModel = Model("models/weapons/c_arms.mdl")
SWEP.WorldModel = ""

SWEP.UseHands = true
SWEP.LowerAngles = Angle(0, 5, -14)
SWEP.LowerAngles2 = Angle(0, 5, -19)
SWEP.KnockViewPunchAngle = Angle(-1.3, 1.8, 0)

SWEP.FireWhenLowered = true
SWEP.HoldType = "fist"

SWEP.holdDistance = 100 -- its actually a drop distance 
SWEP.maxHoldDistance = 96 -- how far away the held object is allowed to travel before forcefully dropping
SWEP.maxHoldStress = 4000 -- how much stress the held object can undergo before forcefully dropping

SWEP.HandsUp = nil

-- luacheck: globals ACT_VM_FISTS_DRAW ACT_VM_FISTS_HOLSTER
ACT_VM_FISTS_DRAW = 2
ACT_VM_FISTS_HOLSTER = 1


function SWEP:Initialize()
	self:SetHoldType(self.HoldType)
	self.HandsUp = false

	self.lastHand = 0
	self.maxHoldDistanceSquared = self.maxHoldDistance ^ 2
	self.heldObjectAngle = Angle(angle_zero)
end

if (CLIENT) then
	function SWEP:DoDrawCrosshair(x, y)
		surface.SetDrawColor(255, 255, 255, 66)
		surface.DrawRect(x - 2, y - 2, 4, 4)
	end

	hook.Add("CreateMove", "ixHandsCreateMove", function(cmd)
		if (LocalPlayer():GetLocalVar("bIsHoldingObject", false) and cmd:KeyDown(IN_ATTACK2)) then
			cmd:ClearMovement()
			local angle = RenderAngles()
			angle.z = 0
			cmd:SetViewAngles(angle)
		end
	end)
end

function SWEP:Deploy()
	if (!IsValid(self:GetOwner())) then
		return
	end

	local viewModel = self:GetOwner():GetViewModel()

	if (IsValid(viewModel)) then
		viewModel:SetPlaybackRate(1)
		viewModel:ResetSequence(ACT_VM_FISTS_DRAW)
		if CLIENT then
			self.NextAllowedPlayRateChange = CurTime() + viewModel:SequenceDuration()
		end
	end

	self:DropObject()
	return true
end

function SWEP:Precache()
	util.PrecacheSound("npc/vort/claw_swing1.wav")
	util.PrecacheSound("npc/vort/claw_swing2.wav")
	util.PrecacheSound("physics/plastic/plastic_box_impact_hard1.wav")
	util.PrecacheSound("physics/plastic/plastic_box_impact_hard2.wav")
	util.PrecacheSound("physics/plastic/plastic_box_impact_hard3.wav")
	util.PrecacheSound("physics/plastic/plastic_box_impact_hard4.wav")
	util.PrecacheSound("physics/wood/wood_crate_impact_hard2.wav")
	util.PrecacheSound("physics/wood/wood_crate_impact_hard3.wav")
end

function SWEP:OnReloaded()
	self.maxHoldDistanceSquared = self.maxHoldDistance ^ 2
	self:DropObject()
end

function SWEP:Holster()
	if (!IsValid(self:GetOwner())) then
		return
	end

	local viewModel = self:GetOwner():GetViewModel()

	if (IsValid(viewModel)) then
		viewModel:SetPlaybackRate(1)
		viewModel:ResetSequence(ACT_VM_FISTS_HOLSTER)
		if CLIENT then
			self.NextAllowedPlayRateChange = CurTime() + viewModel:SequenceDuration()
		end
	end

	return true
end

function SWEP:Think()
	if (!IsValid(self:GetOwner())) then
		return
	end

	if (CLIENT) then
		local viewModel = self:GetOwner():GetViewModel()

		if (IsValid(viewModel) and self.NextAllowedPlayRateChange < CurTime()) then
			viewModel:SetPlaybackRate(1)
		end

		if self:GetOwner():GetLocalVar("bIsHoldingObject", true) then

			if IsValid(self.ghostProp) then
				local tr = util.TraceLine({
					start = self:GetOwner():GetShootPos(),
					endpos = self:GetOwner():GetShootPos() + self:GetOwner():GetAimVector() * self.holdDistance,
					filter = function(ent) if ent != self:GetOwner() then return true end end
				})
	
				local hitPos = tr.HitPos
				local hitNormal = tr.HitNormal
	
				-- Update the ghost prop's model to match the held entity's model, if available and different
				if IsValid(self.heldEntity) and self.ghostProp:GetModel() ~= self.heldEntity:GetModel() then
					self.ghostProp:SetModel(self.heldEntity:GetModel())
				end
	
				-- Use OBB to adjust position so the ghost prop's base aligns with the surface
				local model = self.ghostProp:GetModel()
				local mins, maxs = self.ghostProp:GetModelBounds()
	
				-- Calculate the offset needed to position the model correctly based on its bounding box
				local offset = hitPos + hitNormal * (maxs.z - mins.z) * 0.5
	
				self.ghostProp:SetPos(offset)
				--self.ghostProp:SetAngles(Angle(0, self:GetOwner():EyeAngles().y, 0))
				self.ghostProp:SetAngles(self.heldObjectAngle)
	
				-- Optionally, you can make the ghost prop follow the surface normal
				-- local angleNormal = hitNormal:Angle()
				-- local newAngles = Angle(0, self:GetOwner():EyeAngles().y, 0)
				-- newAngles:RotateAroundAxis(angleNormal:Right(), -90)
				-- self.ghostProp:SetAngles(newAngles)
			else
				self:GhostProp()
			end
        else
			if (IsValid(self.ghostProp)) then
				self.ghostProp:Remove()
			end
		end
	else
		if (self:IsHoldingObject()) then

			local physics = self:GetHeldPhysicsObject()
			local bIsRagdoll = self.heldEntity:IsRagdoll()
			local holdDistance = bIsRagdoll and self.holdDistance * 0.5 or self.holdDistance
			local targetLocation = self:GetOwner():GetShootPos() + self:GetOwner():GetForward() * holdDistance

			if (bIsRagdoll) then
				targetLocation.z = math.min(targetLocation.z, self:GetOwner():GetShootPos().z - 32)
			end

			if (!IsValid(physics)) then
				self:DropObject()
				return
			end

			local currentPlayerAngles = self:GetOwner():EyeAngles()
			local client = self:GetOwner()

			if (client:KeyDown(IN_ATTACK2)) then
				local cmd = client:GetCurrentCommand()
				self.heldObjectAngle:RotateAroundAxis(currentPlayerAngles:Forward(), cmd:GetMouseX() / 15)
				self.heldObjectAngle:RotateAroundAxis(currentPlayerAngles:Right(), cmd:GetMouseY() / 15)
			end

			self.lastPlayerAngles = self.lastPlayerAngles or currentPlayerAngles
			self.heldObjectAngle.y = self.heldObjectAngle.y - math.AngleDifference(self.lastPlayerAngles.y, currentPlayerAngles.y)
			self.lastPlayerAngles = currentPlayerAngles
		end
		-- Prevents the camera from getting stuck when the object that the client is holding gets deleted.
		if(!IsValid(self.heldEntity) and self:GetOwner():GetLocalVar("bIsHoldingObject", true)) then
			self:GetOwner():SetLocalVar("bIsHoldingObject", false)
		end
	end
end

function SWEP:GetHeldPhysicsObject()
	return IsValid(self.heldEntity) and self.heldEntity:GetPhysicsObject() or nil
end

function SWEP:CanHoldObject(entity)
	local physics = entity:GetPhysicsObject()

	return IsValid(physics) and
		(physics:GetMass() <= ix.config.Get("maxHoldWeight", 100) and physics:IsMoveable()) and
		!self:IsHoldingObject() and
		!IsValid(entity.ixHeldOwner) and
		hook.Run("CanPlayerHoldObject", self:GetOwner(), entity)
end

function SWEP:IsHoldingObject()
	return IsValid(self.heldEntity)
end

function SWEP:PickupObject(entity)
    if (self:IsHoldingObject() or
        !IsValid(entity) or
        !IsValid(entity:GetPhysicsObject())) then
        return
    end

    local attachmentIndex = self.Owner:LookupAttachment("anim_attachment_RH")
    if attachmentIndex == 0 then return end -- The attachment does not exist

    local attachment = self.Owner:GetAttachment(attachmentIndex)
    if not attachment then return end

	entity.ixHeldOwner = self:GetOwner()
	entity:SetCollisionGroup(COLLISION_GROUP_WEAPON)

	self.heldObjectAngle = entity:GetAngles()

    self.heldEntity = entity
    self.heldEntity:SetParent(self.Owner, attachmentIndex)
    self.heldEntity:SetLocalPos(Vector(0, 0, 0)) -- Adjust these values as needed
    self.heldEntity:SetLocalAngles(Angle(0, 0, 0)) -- Adjust these values as needed

    local physics = entity:GetPhysicsObject()
    if IsValid(physics) then
        physics:EnableMotion(false) -- Disable physics since it's now parented
    end

    self:GetOwner():SetNWEntity("ixHeldEntity", entity) -- Networked for clients

    if CLIENT then
        self:GhostProp()
    end

	local trace = self:GetOwner():GetEyeTrace()

	if (trace.Entity:IsRagdoll()) then
		local tracedEnt = trace.Entity
		self.holdEntity:SetPos(tracedEnt:GetBonePosition(tracedEnt:TranslatePhysBoneToBone(trace.PhysicsBone)))
	end
end

function SWEP:GhostProp()
    -- Ensure heldEntity is valid before proceeding
	if self:GetOwner():GetLocalVar("bIsHoldingObject", true) then
		local entity = self:GetOwner():GetNWEntity("ixHeldEntity")

		if not IsValid(entity) then
			return
		end
		
		-- Remove existing ghostProp if it exists
		if IsValid(self.ghostProp) then 
			self.ghostProp:Remove() 
		end

		-- Create a new ghostProp with the model of the held entity
		self.ghostProp = ClientsideModel(entity:GetModel(), RENDERGROUP_BOTH)
		self.ghostProp:SetMaterial("models/wireframe")
		self.ghostProp:SetRenderMode(RENDERMODE_TRANSALPHA)
		self.ghostProp:SetColor(Color(255, 255, 255, 100)) -- Example: semi-transparent

		-- Optionally, set ghostProp to not collide with anything
		self.ghostProp:SetCollisionGroup(COLLISION_GROUP_IN_VEHICLE)
	end
end

--[[
local tr = self.Owner:GetEyeTrace()
local hitPos = tr.HitPos

-- Obtain the height of the entity's model
local min, max = self.heldEntity:OBBMins(), self.heldEntity:OBBMaxs()
local height = max.z - min.z

-- Adjust spawn position to be above ground based on the model's height
local spawnPos = hitPos + Vector(0, 0, height / 2)

self.heldEntity:SetParent(nil) -- Unparent
self.heldEntity:SetPos(spawnPos) -- Adjusted spawn position
self.heldEntity:SetAngles(Angle(0, self.Owner:GetAngles().y, 0))
]]


function SWEP:DropObject(bThrow)
    if not IsValid(self.heldEntity) then return end

    local physics = self.heldEntity:GetPhysicsObject()

	local tr = util.TraceLine({
		start = self:GetOwner():GetShootPos(),
		endpos = self:GetOwner():GetShootPos() + self:GetOwner():GetAimVector() * self.holdDistance,
		filter = function(ent) if ent != self:GetOwner() then return true end end
	})

	local hitPos = tr.HitPos
	local hitNormal = tr.HitNormal

	-- Use OBB to adjust position so the ghost prop's base aligns with the surface
	local model = self.heldEntity:GetModel()
	local mins, maxs = self.heldEntity:GetModelBounds()

	-- Calculate the offset needed to position the model correctly based on its bounding box
	local offset = hitPos + hitNormal * (maxs.z - mins.z) * 0.5

	self.heldEntity:SetParent(nil) -- Unparent
	self.heldEntity:SetPos(offset)
	self.heldEntity:SetAngles(self.heldObjectAngle) --Angle(0, self:GetOwner():EyeAngles().y, 0) 

    if IsValid(physics) then
        physics:EnableMotion(true) -- Re-enable physics
        physics:Wake()
        --physics:ApplyForceCenter(self.Owner:GetAimVector() * physics:GetMass() * 200) -- Example force, adjust as needed
    end

    self:GetOwner():SetNWEntity("ixHeldEntity", nil) -- Clear the networked entity
	self.heldEntity.ixHeldOwner = nil
	self.heldEntity.ixCollisionGroup = nil
	self.heldEntity = nil

	if (bThrow) then
		timer.Simple(0, function()
			if (IsValid(physics) and IsValid(self:GetOwner())) then
				physics:AddGameFlag(FVPHYSICS_WAS_THROWN)
				physics:ApplyForceCenter(self:GetOwner():GetAimVector() * ix.config.Get("throwForce", 732))
			end
		end)
	end
end

function SWEP:PlayPickupSound(surfaceProperty)
	local result = "Flesh.ImpactSoft"

	if (surfaceProperty != nil) then
		local surfaceName = util.GetSurfacePropName(surfaceProperty)
		local soundName = surfaceName:gsub("^metal$", "SolidMetal") .. ".ImpactSoft"

		if (sound.GetProperties(soundName)) then
			result = soundName
		end
	end

	self:GetOwner():EmitSound(result, 75, 100, 40)
end

function SWEP:Holster()
	if (!IsFirstTimePredicted() or CLIENT) then
		return
	end

	self:DropObject()
	return true
end

function SWEP:OnRemove()
	if (SERVER) then
		self:DropObject()
	end
end

function SWEP:OwnerChanged()
	if (SERVER) then
		self:DropObject()
	end
end

function SWEP:DoPunchAnimation()
	self.lastHand = math.abs(1 - self.lastHand)

	local sequence = 3 + self.lastHand
	local viewModel = self:GetOwner():GetViewModel()

	if (IsValid(viewModel)) then
		viewModel:SetPlaybackRate(0.5)
		viewModel:SetSequence(sequence)
		if CLIENT then
			self.NextAllowedPlayRateChange = CurTime() + viewModel:SequenceDuration() * 2
		end
	end
end

function SWEP:PrimaryAttack()
	if (!IsFirstTimePredicted()) then
		return
	end

	if (SERVER and self:IsHoldingObject()) then
		self:DropObject(true)
		return
	end


	local Pdelay = math.Clamp((self:GetOwner():GetCharacter():GetAttribute("agility", 0) * 0.008), 0, 1 )

	self:SetNextPrimaryFire(CurTime() + (self.Primary.Delay - Pdelay))

	if (hook.Run("CanPlayerThrowPunch", self:GetOwner()) == false) then
		return
	end

	if (ix.plugin.Get("stamina")) then
		local staminaUseBoost = math.Clamp((self:GetOwner():GetCharacter():GetAttribute("stamina", 0) * 0.1), 0, 10 )
		local staminaUse = ix.config.Get("punchStamina")

		if (staminaUse > 0) then
			local value = self:GetOwner():GetLocalVar("stamina", 0) - staminaUse

			if (value < 0) then
				return
			elseif (SERVER) then
				self:GetOwner():ConsumeStamina(staminaUse - staminaUseBoost)
				--print(staminaUse - staminaUseBoost)
			end
		end
	end

	if (SERVER) then
		self:GetOwner():EmitSound("npc/vort/claw_swing"..math.random(1, 2)..".wav")
	end

	self:DoPunchAnimation()

	self:GetOwner():SetAnimation(PLAYER_ATTACK1)
	self:GetOwner():ViewPunch(Angle(self.lastHand + 2, self.lastHand + 5, 0.125))

	timer.Simple(0.055, function()
		if (IsValid(self) and IsValid(self:GetOwner())) then
			local damage = self.Primary.Damage
			local context = {damage = damage}
			local result = hook.Run("GetPlayerPunchDamage", self:GetOwner(), damage, context)

			if (result != nil) then
				damage = result
			else
				damage = context.damage
			end

			self:GetOwner():LagCompensation(true)
				local data = {}
					data.start = self:GetOwner():GetShootPos()
					data.endpos = data.start + self:GetOwner():GetAimVector() * 50
					data.filter = self:GetOwner()
				local trace = util.TraceLine(data)

				if (SERVER and trace.Hit) then
					local entity = trace.Entity

					if (IsValid(entity)) then
						local damageInfo = DamageInfo()
							damageInfo:SetAttacker(self:GetOwner())
							damageInfo:SetInflictor(self)
							damageInfo:SetDamage(damage)
							damageInfo:SetDamageType(DMG_GENERIC)
							damageInfo:SetDamagePosition(trace.HitPos)
							damageInfo:SetDamageForce(self:GetOwner():GetAimVector() * 1024)
						entity:DispatchTraceAttack(damageInfo, data.start, data.endpos)

						self:GetOwner():EmitSound("physics/body/body_medium_impact_hard"..math.random(1, 6)..".wav", 80)
					end
				end

				hook.Run("PlayerThrowPunch", self:GetOwner(), trace)
			self:GetOwner():LagCompensation(false)
		end
	end)
end

function SWEP:SecondaryAttack()
	if (!IsFirstTimePredicted()) then
		return
	end

	local data = {}
		data.start = self:GetOwner():GetShootPos()
		data.endpos = data.start + self:GetOwner():GetAimVector() * 84
		data.filter = {self, self:GetOwner()}
	local trace = util.TraceLine(data)
	local entity = trace.Entity

	if CLIENT then
		local viewModel = self:GetOwner():GetViewModel()

		if (IsValid(viewModel)) then
			viewModel:SetPlaybackRate(0.5)
			if CLIENT then
				self.NextAllowedPlayRateChange = CurTime() + viewModel:SequenceDuration() * 2
			end
		end
	end

	if (SERVER and IsValid(entity)) then
		if (entity:IsDoor()) then
			if (hook.Run("CanPlayerKnock", self:GetOwner(), entity) == false) then
				return
			end

			self:GetOwner():ViewPunch(self.KnockViewPunchAngle)
			self:GetOwner():EmitSound("physics/wood/wood_crate_impact_hard"..math.random(2, 3)..".wav")
			self:GetOwner():SetAnimation(PLAYER_ATTACK1)

			self:DoPunchAnimation()
			self:SetNextSecondaryFire(CurTime() + 0.4)
			self:SetNextPrimaryFire(CurTime() + 1)

		elseif (entity:IsPlayer() and ix.config.Get("allowPush", true)) then
			local direction = self:GetOwner():GetAimVector() * (300 + (self:GetOwner():GetCharacter():GetAttribute("strength", 0) * 3))
				direction.z = 0
			entity:SetVelocity(direction)

			self:GetOwner():EmitSound("Weapon_Crossbow.BoltHitBody")
			self:SetNextSecondaryFire(CurTime() + 1.5)
			self:SetNextPrimaryFire(CurTime() + 1.5)

		elseif (!entity:IsNPC() and self:CanHoldObject(entity)) then
			self:GetOwner():SetLocalVar("bIsHoldingObject", true)
			self:PickupObject(entity)
			self:PlayPickupSound(trace.SurfaceProps)
			self:SetNextSecondaryFire(CurTime() + self.Secondary.Delay)
		end
	end

	if (self:GetOwner():KeyDown(IN_RELOAD)) then --self:GetOwner():KeyDown(IN_ATTACK2) and
		local client = self:GetOwner()
		if !self.HandsUp then
			
			
			client:ManipulateBoneAngles(client:LookupBone("ValveBiped.Bip01_L_Clavicle"), Angle(-10, 20, -20))
			client:ManipulateBoneAngles(client:LookupBone("ValveBiped.Bip01_L_UpperArm"), Angle(-80, 0, -50))
			client:ManipulateBoneAngles(client:LookupBone("ValveBiped.Bip01_L_Forearm"), Angle(-25, -40, -17))

			client:ManipulateBoneAngles(client:LookupBone("ValveBiped.Bip01_R_Clavicle"), Angle(10, 20, 20))
			client:ManipulateBoneAngles(client:LookupBone("ValveBiped.Bip01_R_UpperArm"), Angle(80, 0, 50))
			client:ManipulateBoneAngles(client:LookupBone("ValveBiped.Bip01_R_Forearm"), Angle(25, -50, 17))
			self.HandsUp = true
		else
			
			client:ManipulateBoneAngles(client:LookupBone("ValveBiped.Bip01_L_Clavicle"), Angle(0, 0, 0))
			client:ManipulateBoneAngles(client:LookupBone("ValveBiped.Bip01_L_UpperArm"), Angle(0, 0, 0))
			client:ManipulateBoneAngles(client:LookupBone("ValveBiped.Bip01_L_Forearm"), Angle(0, 0, 0))

			client:ManipulateBoneAngles(client:LookupBone("ValveBiped.Bip01_R_Clavicle"), Angle(0, 0, 0))
			client:ManipulateBoneAngles(client:LookupBone("ValveBiped.Bip01_R_UpperArm"), Angle(0, 0, 0))
			client:ManipulateBoneAngles(client:LookupBone("ValveBiped.Bip01_R_Forearm"), Angle(0, 0, 0))
			self.HandsUp = false
		end
	end
end

function SWEP:Reload()
	if (!IsFirstTimePredicted()) then
		return
	end

	if (SERVER and IsValid(self.heldEntity)) then
		self:DropObject()
	end
end
