AddCSLuaFile()

SWEP.PrintName	= "Utility Belt"

SWEP.Author		= "8Z"
SWEP.Purpose	= ""

SWEP.Spawnable	= true
SWEP.UseHands	= true
SWEP.DrawAmmo	= false
SWEP.DrawCrosshair= false

SWEP.ViewModel	= "models/weapons/c_arms_citizen.mdl"
SWEP.WorldModel	= "models/weapons/w_defuser.mdl"

SWEP.DrawWorldModel = false

SWEP.ViewModelFOV	= 70
SWEP.Slot			= 4
SWEP.SlotPos		= 1

SWEP.Primary.ClipSize		= -1
SWEP.Primary.DefaultClip	= -1
SWEP.Primary.Automatic		= true
SWEP.Primary.Ammo			= "none"

SWEP.Secondary.ClipSize		= -1
SWEP.Secondary.DefaultClip	= -1
SWEP.Secondary.Automatic	= true
SWEP.Secondary.Ammo			= "none"

-- Refactored to be on the player
--Swep.Owner.BeltSlots = {}
SWEP.SlotCount = 4

-- in Singleplayer, these are maintained serverside and sent to client
-- in Listen/Dedicated servers, these are clientside
-- Why? Because predictable hooks don't like to run on client in SP for some reason
-- and syncing is a headache
SWEP.ActiveSlot = 0
SWEP.NextSlot = 0

local function lookup(slot)
    local tbl = UTILITY_BELT_ITEMS[slot.class]
    if not tbl then
        tbl = {
            bone = "ValveBiped.Bip01_Spine",
            model = slot.model,
            mat = slot.mat,
            color = slot.color,
            pos = Vector(0,0,0),
            ang = Angle(-90,0,90)
        }
    end
    return tbl
end

local function can_pickup(ent)
    local class = ent:GetClass()
    
    -- Must be in explicit whitelist (doubles as model info)
    if not UTILITY_BELT_ITEMS[class] then return false end
    
    -- JMod: Grenades / explosives that are primed/armed/broken can't be picked up
    if ent.GetState and ent:GetState() != 0 then return false end

    return true
end

function SWEP:Initialize()
	self:SetHoldType("normal")
    self.Owner.BeltSlots = {}
end

function SWEP:PrimaryAttack()
    if CLIENT then
        self:ReleaseActive()
    elseif SERVER and game.SinglePlayer() then
        self:ReleaseItem(self.ActiveSlot)
    end
end

function SWEP:SecondaryAttack()
    if self:GetNextSecondaryFire() > CurTime() then return end
    self:SetNextSecondaryFire(CurTime() + 0.1)

    -- Look for something to pick up
    local ent = self.Owner:GetEyeTrace().Entity
    if (IsValid(ent) and !ent.TAKEN and ent:GetPos():DistToSqr(self.Owner:GetPos()) <= 100 * 100 and can_pickup(ent)) then
        for i = 1, self.SlotCount do
            if self.Owner.BeltSlots[i] == nil then
                -- Add the item to the slot
                ent.TAKEN = true
                
                self.Owner.BeltSlots[i] = {
                    class = ent:GetClass(),
                    model = ent:GetModel(),
                    mat = ent:GetMaterial(),
                    color = ent:GetColor()
                }
                if game.SinglePlayer() then
                    -- Predicted hooks aren't called on client in singleplayer
                    net.Start("utility_belt")
                        net.WriteEntity(self.Owner)
                        net.WriteBool(true)
                        net.WriteUInt(i, 4)
                        net.WriteString(ent:GetClass())
                        net.WriteString(ent:GetModel())
                        net.WriteString(ent:GetMaterial() or "")
                        net.WriteColor(Color(ent:GetColor().r,ent:GetColor().g,ent:GetColor().b,ent:GetColor().a or 255))
                    net.Broadcast()
                    wep:FindSlots(false)
                end
                if SERVER then self.Owner:EmitSound("items/ammopickup.wav") end
                SafeRemoveEntity(ent)
                break
            end
        end
    end
end

local pressed = false
function SWEP:Think()
    
    if not pressed and self.Owner:KeyDown(IN_RELOAD) then
        pressed = true
        if (SERVER and game.SinglePlayer()) or (CLIENT and not game.SinglePlayer()) then
            self:FindSlots(true)
        end
        if CLIENT then surface.PlaySound("ui/buttonrollover.wav") end
    elseif pressed and not self.Owner:KeyDown(IN_RELOAD) then
        pressed = false
    end
end

UTILITY_BELT_OFFSET = {
    ["ValveBiped.Bip01_Spine"] = {
        [1] = {pos = Vector(-6,0,4), ang = Angle(0,-10,15)},
        [2] = {pos = Vector(-6,0,-4), ang = Angle(0,-10,-15)},
        [3] = {pos = Vector(-2,0,8), ang = Angle(0,-10,60)},
        [4] = {pos = Vector(-2,0,-8), ang = Angle(0,-10,-60)}
    },
    ["ValveBiped.Bip01_Spine1"] = {
        [1] = {pos = Vector(-3,-4,6), ang = Angle(0,0,70)},
        [2] = {pos = Vector(-3,-4,-6), ang = Angle(0,0,-70)},
        [3] = {pos = Vector(3,-4,4), ang = Angle(180,180,-30)},
        [4] = {pos = Vector(3,-4,-4), ang = Angle(180,180,30)},
    },
}

UTILITY_BELT_ITEMS = {

    -- HL2
    ["item_healthvial"] = {
        bone = "ValveBiped.Bip01_Spine",
        model = "models/healthvial.mdl",
        mat = "",
        color = Color(255,255,255),
        scale = Vector(1,1,1),
        pos = Vector(0,0,0),
        ang = Angle(90,0,-90)
    },
    ["item_healthkit"] = {
        bone = "ValveBiped.Bip01_Spine1",
        model = "models/items/healthkit.mdl",
        mat = "",
        color = Color(255,255,255),
        scale = Vector(0.7,0.7,0.7),
        pos = Vector(0,0,0),
        ang = Angle(0,180,-90)
    },
    ["item_battery"] = {
        bone = "ValveBiped.Bip01_Spine",
        model = "models/items/battery.mdl",
        mat = "",
        color = Color(255,255,255),
        scale = Vector(0.8,0.8,0.8),
        pos = Vector(0,0,0),
        ang = Angle(90,0,-90)
    },
    
    -- JMod grenades
    ["ent_jack_gmod_ezfragnade"] = {
        bone = "ValveBiped.Bip01_Spine",
        model = "models/weapons/w_fragjade.mdl",
        mat = "",
        color = Color(255,255,255),
        scale = Vector(1.2,1.2,1.2),
        pos = Vector(-2,-4,0),
        ang = Angle(-90,0,90)
    },
    ["ent_jack_gmod_ezfirenade"] = {
        bone = "ValveBiped.Bip01_Spine",
        model = "models/grenades/incendiary_grenade.mdl",
        mat = "",
        color = Color(255,255,255),
        scale = Vector(1,1,1),
        pos = Vector(-1,-4,0),
        ang = Angle(-90,0,90)
    },
    ["ent_jack_gmod_ezimpactnade"] = {
        bone = "ValveBiped.Bip01_Spine",
        model = "models/grenades/impact_grenade.mdl",
        mat = "",
        color = Color(255,255,255),
        scale = Vector(1,1,1),
        pos = Vector(-1,-4,0),
        ang = Angle(-90,0,90)
    },
    ["ent_jack_gmod_ezflashbang"] = {
        bone = "ValveBiped.Bip01_Spine",
        model = "models/conviction/flashbang.mdl",
        mat = "",
        color = Color(255,255,255),
        scale = Vector(1,1,1),
        pos = Vector(-1,-5,0),
        ang = Angle(-90,0,90)
    },
    ["ent_jack_gmod_ezgasnade"] = {
        bone = "ValveBiped.Bip01_Spine",
        model = "models/grenades/gas_grenade.mdl",
        mat = "",
        color = Color(255,255,255),
        scale = Vector(1,1,1),
        pos = Vector(-1,-5,0),
        ang = Angle(-90,0,90)
    },
    ["ent_jack_gmod_ezsticknade"] = {
        bone = "ValveBiped.Bip01_Spine",
        model = "models/grenades/stick_grenade.mdl",
        mat = "models/mats_jack_nades/stick_grenade",
        color = Color(255,255,255),
        scale = Vector(0.9,0.9,0.9),
        pos = Vector(-1,-1,0),
        ang = Angle(80,0,90)
    },
    ["ent_jack_gmod_ezsticknadebundle"] = {
        bone = "ValveBiped.Bip01_Spine1",
        model = "models/grenades/bundle_grenade.mdl",
        mat = "models/mats_jack_nades/stick_grenade",
        color = Color(255,255,255),
        scale = Vector(0.9,0.9,0.9),
        pos = Vector(-2,-3,0),
        ang = Angle(90,0,90)
    },
    ["ent_jack_gmod_ezsmokenade"] = {
        bone = "ValveBiped.Bip01_Spine",
        model = "models/grenades/incendiary_grenade.mdl",
        mat = "models/mats_jack_nades/smokescreen",
        color = Color(255,255,255),
        scale = Vector(1,1,1),
        pos = Vector(-1,-4,0),
        ang = Angle(-90,0,90)
    },
    ["ent_jack_gmod_ezsignalnade"] = {
        bone = "ValveBiped.Bip01_Spine",
        model = "models/grenades/incendiary_grenade.mdl",
        mat = "models/mats_jack_nades/smokesignal",
        color = Color(255,255,255),
        scale = Vector(1,1,1),
        pos = Vector(-1,-4,0),
        ang = Angle(-90,0,90)
    },
    ["ent_jack_gmod_ezstickynade"] = {
        bone = "ValveBiped.Bip01_Spine",
        model = "models/grenades/sticky_grenade.mdl",
        mat = "",
        color = Color(255,255,255),
        scale = Vector(1,1,1),
        pos = Vector(-1,-3,0),
        ang = Angle(90,0,90)
    },
    ["ent_jack_gmod_eznade_impact"] = {
        bone = "ValveBiped.Bip01_Spine",
        model = "models/weapons/w_fragjade.mdl",
        mat = "models/mats_jack_nades/gnd_blk",
        color = Color(255,255,255),
        scale = Vector(1,1,1),
        pos = Vector(-1,-4,0),
        ang = Angle(-90,0,90)
    },
    ["ent_jack_gmod_eznade_proximity"] = {
        bone = "ValveBiped.Bip01_Spine",
        model = "models/weapons/w_fragjade.mdl",
        mat = "models/mats_jack_nades/gnd_red",
        color = Color(255,255,255),
        scale = Vector(1,1,1),
        pos = Vector(-1,-4,0),
        ang = Angle(-90,0,90)
    },
    ["ent_jack_gmod_eznade_remote"] = {
        bone = "ValveBiped.Bip01_Spine",
        model = "models/weapons/w_fragjade.mdl",
        mat = "models/mats_jack_nades/gnd_blu",
        color = Color(255,255,255),
        scale = Vector(1,1,1),
        pos = Vector(-1,-4,0),
        ang = Angle(-90,0,90)
    },
    ["ent_jack_gmod_eznade_timed"] = {
        bone = "ValveBiped.Bip01_Spine",
        model = "models/weapons/w_fragjade.mdl",
        mat = "models/mats_jack_nades/gnd_ylw",
        color = Color(255,255,255),
        scale = Vector(1,1,1),
        pos = Vector(-1,-4,0),
        ang = Angle(-90,0,90)
    },
    
    
    
    
    -- JMod explosives
    ["ent_jack_gmod_ezboundingmine"] = {
        bone = "ValveBiped.Bip01_Spine1",
        model = "models/grenades/bounding_mine.mdl",
        mat = "",
        color = Color(255,255,255),
        scale = Vector(1,1,1),
        pos = Vector(-2,-4,0),
        ang = Angle(-90,0,90)
    },
    ["ent_jack_gmod_eztnt"] = {
        bone = "ValveBiped.Bip01_Spine1",
        model = "models/weapons/w_jnt.mdl",
        mat = "",
        color = Color(255,255,255),
        scale = Vector(0.8,0.8,0.8),
        pos = Vector(-2,-4,0),
        ang = Angle(0,0,90)
    },
    ["ent_jack_gmod_ezminimore"] = {
        bone = "ValveBiped.Bip01_Spine1",
        model = "models/weapons/w_clayjore.mdl",
        mat = "models/mat_jack_claymore",
        color = Color(255,255,255),
        scale = Vector(0.8,0.8,0.8),
        pos = Vector(-2,-8,0),
        ang = Angle(-90,0,-90)
    },
    ["ent_jack_gmod_ezdetpack"] = {
        bone = "ValveBiped.Bip01_Spine1",
        model = "models/props_misc/tobacco_box-1.mdl",
        mat = "models/entities/mat_jack_c4",
        color = Color(255,255,255),
        scale = Vector(0.8,0.8,0.8),
        pos = Vector(-2,-2,0),
        ang = Angle(90,-90,0)
    },
    ["ent_jack_gmod_ezdynamite"] = {
        bone = "ValveBiped.Bip01_Spine",
        model = "models/mechanics/robotics/a2.mdl",
        mat = "models/entities/mat_jack_dynamite",
        color = Color(255,255,255),
        scale = Vector(0.2,0.2,0.2),
        pos = Vector(-2,-2,0),
        ang = Angle(0,0,0)
    },
    ["ent_jack_gmod_ezslam"] = {
        bone = "ValveBiped.Bip01_Spine",
        model = "models/weapons/w_jlam.mdl",
        mat = "",
        color = Color(255,255,255),
        scale = Vector(1,1,1),
        pos = Vector(-2,-2,0),
        ang = Angle(-90,90,0)
    },
    -- On second thought, let's not allow players to lug four nuclear bombs around
    
    ["ent_jack_gmod_eznuke_small"] = {
        bone = "ValveBiped.Bip01_Spine1",
        model = "models/chappi/mininuq.mdl",
        mat = "",
        color = Color(255,255,255),
        scale = Vector(0.8,0.8,0.8),
        pos = Vector(-2,-2,0),
        ang = Angle(0,-90,0)
    },
    
}

-- This is run serverside in singleplayer and clientside on servers, see comment on ActiveSlot
function SWEP:FindSlots(increment)

    print("FindSlots")
    local cur = self.ActiveSlot - 1

    self.ActiveSlot = 0
    self.NextSlot = 0
    
    --print("looking for ActiveSlot")
    for i = (increment and 1 or 0), 4 do
        local slot = (cur + i) % 4 + 1
        --print("i = " .. i .. " (" .. slot .. ")")
        if self.Owner.BeltSlots[slot] then
            --print("found")
            self.ActiveSlot = slot
            break
        end
    end
    
    if self.ActiveSlot == 0 then return end
    cur = self.ActiveSlot - 1
    --print("looking for NextSlot")
    for i = 1, 3 do
        local slot = (cur + i) % 4 + 1
        --print("i = " .. i .. " (" .. slot .. ")")
        if self.Owner.BeltSlots[slot] then
            --print("found")
            self.NextSlot = slot
            break
        end
    end
    
    if SERVER and game.SinglePlayer() then
        net.Start("utility_belt_slot")
            net.WriteUInt(self.ActiveSlot, 4)
            net.WriteUInt(self.NextSlot, 4)
        net.Send(self.Owner)
    end
end

// TODO this entire part is wack
hook.Add("PlayerButtonDown", "utility_belt_key", function(ply, key)

    local wep = ply:GetWeapon("utility_belt")
    if not IsValid(wep) or not wep.Owner.BeltSlots or table.Count(wep.Owner.BeltSlots) <= 0 or wep.Owner.BeltSlots[wep.ActiveSlot] == nil then return end

    if key == KEY_G and ply:KeyDown(IN_WALK) then
        if (SERVER and game.SinglePlayer()) or (CLIENT and not game.SinglePlayer()) then
            wep:FindSlots(true)
        end
        if CLIENT then surface.PlaySound("ui/buttonrollover.wav") end
    elseif key == KEY_G and not ply:KeyDown(IN_WALK) then
        if game.SinglePlayer() then
            wep:ReleaseItem(wep.ActiveSlot)
            wep:FindSlots(false)
        elseif CLIENT then
            net.Start("utility_belt")
                net.WriteUInt(wep.ActiveSlot, 4)
            net.SendToServer()
            timer.Simple(0, function() wep:FindSlots(false) end)
        end
    end
end)

hook.Add("StartCommand", "utility_belt_hack", function(ply, cmd)
    -- Since IN_ATTACK is pressed to release object and also to throw object, this causes the object to be instantly thrown (bad!)
    -- This blocks IN_ATTACK for a bit so that the player can release IN_ATTACK (or not, I guess) to hold it
	if cmd:KeyDown(IN_ATTACK) and ply.UTILITY_BELT_HACK then
		cmd:SetButtons(bit.band(cmd:GetButtons(), bit.bnot(IN_ATTACK)))
	end
end)

if SERVER then
    -- SERVER -> CLIENT: Updates slot information (only used in singleplayer)
    -- CLIENT -> SERVER: Release item of specified index
    util.AddNetworkString("utility_belt")
    
    -- SERVER -> CLIENT: Updates activeslot and nextslot (only in singleplayer)
    util.AddNetworkString("utility_belt_slot")
    
    net.Receive("utility_belt", function(len, ply)
        local wep = ply:GetWeapon("utility_belt")
        if not IsValid(wep) or not IsValid(ply) then return end
        local i = net.ReadUInt(4)
        wep:ReleaseItem(i)
    end)
    
    function SWEP:ReleaseItem(i)

        if self:GetNextPrimaryFire() > CurTime() or self.Owner.BeltSlots[i] == nil or (IsValid(self.LastThrow) and self.LastThrow:IsPlayerHolding()) then return end
        if self.Owner:GetEyeTrace().HitPos:DistToSqr(self.Owner:EyePos()) < 60 * 60 then return end
        self:SetNextPrimaryFire(CurTime() + 1)
        self.LastThrow = nil

        local ent = ents.Create(self.Owner.BeltSlots[i].class)
        ent:SetModel(self.Owner.BeltSlots[i].model)
        ent:SetColor(self.Owner.BeltSlots[i].color)
        ent:SetPos(self.Owner:EyePos() + self.Owner:GetAimVector() * 30)
        ent:SetAngles(self.Owner:GetAngles())
        ent:Spawn()
        self.Owner.UTILITY_BELT_HACK = true
        if ent.Base == "ent_jack_gmod_ezgrenade" then
            if self.Owner:KeyDown(IN_USE) then JMod_ThrowablePickup(self.Owner,ent,ent.HardThrowStr,ent.SoftThrowStr) end
            if self.Owner:KeyDown(IN_ATTACK) and isfunction(ent.Prime) then ent:Prime() end
        else
            if self.Owner:KeyDown(IN_USE) or self.Owner:KeyDown(IN_ATTACK)then self.Owner:PickupObject(ent) end
        end
        timer.Simple(0.25, function() if IsValid(self.Owner) then self.Owner.UTILITY_BELT_HACK = false end end)
        self.Owner:EmitSound("weapons/zoom.wav")
        self.LastThrow = ent

        self.Owner.BeltSlots[i] = nil
        if game.SinglePlayer() then
            self:FindSlots(false)
        end            
        net.Start("utility_belt")
            net.WriteEntity(self.Owner)
            net.WriteBool(false)
            net.WriteUInt(i, 4)
        net.Broadcast()
    end
    
    function SWEP:ScatterItems(detonate, instant)
        local j = 0
        for i = 1, 4 do
            local slot = self.Owner.BeltSlots[i]
            if slot ~= nil then
            
                local tbl = lookup(slot)
                local bIndex = self.Owner:LookupBone(tbl.bone)
                local bPos, bAng = self.Owner:GetBonePosition(bIndex)
                local off = UTILITY_BELT_OFFSET[tbl.bone][i]
                local vel = self.Owner:GetPhysicsObject():GetVelocity()
        
                local ent = ents.Create(slot.class)
                ent:SetModel(tbl.model)
                ent:SetMaterial(slot.mat or tbl.mat or "")
                ent:SetColor(slot.color)
                
                if bIndex and bPos and bAng and off then
                    local r,f,u = bAng:Right(), bAng:Forward(), bAng:Up()
                    bPos = bPos + r * tbl.pos.x + f * tbl.pos.y + u * tbl.pos.z
                    bPos = bPos + r * off.pos.x + f * off.pos.y + u * off.pos.z
                    
                    bAng:RotateAroundAxis(r, tbl.ang.p)
                    bAng:RotateAroundAxis(u, tbl.ang.y)
                    bAng:RotateAroundAxis(f, tbl.ang.r)
                    bAng:RotateAroundAxis(r, off.ang.p)
                    bAng:RotateAroundAxis(u, off.ang.y)
                    bAng:RotateAroundAxis(f, off.ang.r)
                    
                    ent:SetPos(bPos)
                    ent:SetAngles(bAng)
                else
                    ent:SetPos(self.Owner:GetPos())
                end
                JMod_Owner(ent, self.Owner)
            
                if detonate then
                    ent:SetCollisionGroup(COLLISION_GROUP_WEAPON)
                    timer.Simple(j * 0.1, function()
                        ent:Spawn()
                        ent:GetPhysicsObject():SetVelocity(vel)
                        if instant and ent.Detonate then
                            ent:Detonate()
                        elseif not instant then
                            if ent.Prime then 
                                ent:Prime()
                            elseif ent.Arm then 
                                ent:Arm()
                            elseif ent.Detonate then
                                timer.Simple(math.random() + 1, function()
                                    if IsValid(ent) then ent:Detonate() end
                                end)
                            end
                        end
                    end)
                    j = j + 1
                else
                    ent:Spawn()
                    ent:GetPhysicsObject():SetVelocity(vel)
                end
            end
        end
        self.Owner.BeltSlots = {}
        net.Start("utility_belt")
            net.WriteEntity(self.Owner)
            net.WriteBool(false)
            net.WriteUInt(0, 4)
        net.Broadcast()
    end
    
    hook.Add("PlayerSpawn", "utility_belt_spawn", function(ply)
        ply.BeltSlots = {}
        net.Start("utility_belt")
            net.WriteEntity(ply)
            net.WriteBool(false)
            net.WriteUInt(0, 4)
        net.Broadcast()
    end)
    
    hook.Add("PlayerDeath", "utility_belt_drop", function(ply)
    
        local wep = ply:GetWeapon("utility_belt")
        if not IsValid(wep) or not wep.Owner.BeltSlots or table.Count(wep.Owner.BeltSlots) <= 0 then return end
        
        local det = ply:GetWeapon("utility_belt_detonator")
        if IsValid(det) and det.DeadManSwitch then
            wep:ScatterItems(true)
        else
            wep:ScatterItems(false)
        end
    
    end)
end

if CLIENT then

    function SWEP:ReleaseActive()
        if self.Owner.BeltSlots[self.ActiveSlot] == nil then return end
        net.Start("utility_belt")
            net.WriteUInt(self.ActiveSlot, 4)
        net.SendToServer()
        timer.Simple(0, function() self:FindSlots(false) end)
    end
    
    function SWEP:DrawWorldModel()
    end
    
    net.Receive("utility_belt", function()
        local ply = net.ReadEntity()
        local write = net.ReadBool()
        local index = net.ReadUInt(4)
        if write == false then
            if index == 0 then
                ply.BeltSlots = {}
            else
                ply.BeltSlots[index] = nil
            end
        else
            local class = net.ReadString()
            local mdl = net.ReadString()
            local mat = net.ReadString()
            local color = net.ReadColor()
            ply.BeltSlots[index] = {
                class = class,
                model = mdl,
                mat = mat,
                color = color
            }
        end
        if not game.SinglePlayer() and ply:GetWeapon("utility_belt") then ply:GetWeapon("utility_belt"):FindSlots(false) end
    end)
    
    net.Receive("utility_belt_slot", function()
        local wep = LocalPlayer():GetWeapon("utility_belt")
        if not IsValid(wep) or not IsValid(ply) then return end
        wep.ActiveSlot = net.ReadUInt(4)
        wep.NextSlot = net.ReadUInt(4)
    end)
    
    local matOverlay_Normal = Material( "gui/ContentIcon-normal.png" )
    local matOverlay_Hovered = Material( "gui/ContentIcon-hovered.png" )
    local mat_hover = Material("vgui/spawnmenu/hover")
    local curmat = nil
    local nextmat = nil
    
    hook.Add("HUDPaint", "utility_belt_quickhud", function()
        local wep = LocalPlayer():GetWeapon("utility_belt")
        if not LocalPlayer():Alive() or not IsValid(wep) or not LocalPlayer().BeltSlots or table.Count(LocalPlayer().BeltSlots) <= 0 then return end
        
        local x = ScrW() * 0.15
        local y = ScrH() - 150
        local scale = 1
        
        surface.SetDrawColor( 255, 255, 255, 255 )
        
        if wep.ActiveSlot ~= 0 and LocalPlayer().BeltSlots[wep.ActiveSlot] ~= nil then

            local path = "entities/" .. LocalPlayer().BeltSlots[wep.ActiveSlot].class
            if not curmat or curmat:GetName() ~= path then
                curmat = Material( path .. ".png" )
            end
            
            surface.SetMaterial( curmat )
            surface.DrawTexturedRect( x + 3, y + 3, (128 - 6) * scale, (128 - 6) * scale )
            
            surface.SetMaterial( matOverlay_Normal )
            surface.DrawTexturedRect( x, y, 128 * scale, 128 * scale )

            draw.SimpleTextOutlined("ACTIVE QUICKBELT", "DermaDefault", x + 64 * scale, y + 2, Color(255,255,255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, Color(50,50,50))
        end
        
        if wep.NextSlot ~= 0 and LocalPlayer().BeltSlots[wep.NextSlot] ~= nil then
        
            local path = "entities/" .. LocalPlayer().BeltSlots[wep.NextSlot].class
            if not nextmat or nextmat:GetName() ~= path then
                nextmat = Material( path .. ".png" )
            end
            
            local x2 = x + 128 * scale
            local y2 = y + 64 * scale
            
            surface.SetMaterial( nextmat )
            surface.DrawTexturedRect( x2 + 1.5, y2 + 1.5, (64 - 3) * scale, (64 - 3) * scale )
            
            surface.SetMaterial( matOverlay_Hovered )
            surface.DrawTexturedRect( x2, y2, 64 * scale, 64 * scale )

            draw.SimpleTextOutlined("NEXT", "DermaDefault", x2 + 32 * scale, y2 + 2, Color(255,255,255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, Color(50,50,50))
        end
        
    end)
    
    -- Draw models on player
    hook.Add("PostPlayerDraw", "utility_belt_render", function(ply)
        
        ply.BeltModels = ply.BeltModels or {}
        local wep = ply:GetWeapon("utility_belt")
        
        if not LocalPlayer().BeltSlots or table.Count(LocalPlayer().BeltSlots) <= 0 then 
            -- Clean up any models if they exist
            if IsValid(ply.BeltModels) and istable(ply.BeltModels) and table.Count(wep.Owner.BeltSlots) > 0 then 
                for _, mdl in pairs(ply.BeltModels) do mdl:Remove() end 
            end
            return 
        end

        for i = 1, 4 do
        
            local slot = wep.Owner.BeltSlots[i]
            
            if not slot then
                if IsValid(ply.BeltModels[i]) then 
                    ply.BeltModels[i]:Remove() 
                    ply.BeltModels[i] = nil 
                end
            else
            
                local tbl = lookup(slot)
                local mdl = ply.BeltModels[i]
                
                if IsValid(mdl) and mdl:GetModel() ~= tbl.model then
                    mdl:Remove()
                end
                
                if not IsValid(mdl) then 
                    mdl = ClientsideModel(tbl.model) 
                    mdl:SetModel(tbl.model)
                    mdl:SetPos(ply:GetPos())
                    mdl:SetMaterial(tbl.mat or "")
                    mdl:SetParent(ply)
                    mdl:SetNoDraw(true)
                    ply.BeltModels[i] = mdl
                end
                
                local bIndex = ply:LookupBone(tbl.bone)
                local bPos,bAng = ply:GetBonePosition(bIndex)
                local off = UTILITY_BELT_OFFSET[tbl.bone][i]
                
                if IsValid(mdl) and bIndex and bPos and bAng and off then
                
                    local r,f,u = bAng:Right(), bAng:Forward(), bAng:Up()
                    
                    bPos = bPos + r * tbl.pos.x + f * tbl.pos.y + u * tbl.pos.z
                    bPos = bPos + r * off.pos.x + f * off.pos.y + u * off.pos.z
                    
                    bAng:RotateAroundAxis(r, tbl.ang.p)
                    bAng:RotateAroundAxis(u, tbl.ang.y)
                    bAng:RotateAroundAxis(f, tbl.ang.r)
                    bAng:RotateAroundAxis(r, off.ang.p)
                    bAng:RotateAroundAxis(u, off.ang.y)
                    bAng:RotateAroundAxis(f, off.ang.r)
                    
                    mdl:SetRenderOrigin(bPos)
                    mdl:SetRenderAngles(bAng)
                    
                    if tbl.scale then 
                        local m = Matrix()
                        m:Scale(tbl.scale)
                        mdl:EnableMatrix("RenderMultiply",m)
                    end
                    
                    if tbl.color then
                        local r,g,b=render.GetColorModulation()
                        render.SetColorModulation(tbl.color.r/255,tbl.color.g/255,tbl.color.b/255)
                        mdl:DrawModel()
                        render.SetColorModulation(r,g,b)
                    end
                end
            end
        end
    end)
end