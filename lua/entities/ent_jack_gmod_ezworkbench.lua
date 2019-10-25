-- Jackarunda 2019
AddCSLuaFile()
ENT.Type="anim"
ENT.PrintName="EZ Workbench"
ENT.Author="Jackarunda"
ENT.Category="JMod - EZ"
ENT.Information="glhfggwpezpznore"
ENT.Spawnable=true
ENT.AdminSpawnable=true
ENT.RenderGroup=RENDERGROUP_TRANSLUCENT
ENT.EZconsumes={"power","fuel"}
---
function ENT:SetupDataTables()
	self:NetworkVar("Float",0,"Electricity")
	self:NetworkVar("Float",1,"Fuel")
end
if(SERVER)then
	function ENT:SpawnFunction(ply,tr)
		local SpawnPos=tr.HitPos+tr.HitNormal*20
		local ent=ents.Create(self.ClassName)
		ent:SetAngles(Angle(0,0,0))
		ent:SetPos(SpawnPos)
		ent.Owner=ply
		ent:Spawn()
		ent:Activate()
		--local effectdata=EffectData()
		--effectdata:SetEntity(ent)
		--util.Effect("propspawn",effectdata)
		return ent
	end
	function ENT:Initialize()
		self.Entity:SetModel("models/mosi/fallout4/furniture/workstations/weaponworkbench01.mdl")
		self.Entity:PhysicsInit(SOLID_VPHYSICS)
		self.Entity:SetMoveType(MOVETYPE_VPHYSICS)
		self.Entity:SetSolid(SOLID_VPHYSICS)
		self.Entity:DrawShadow(true)
		self:SetUseType(SIMPLE_USE)
		local phys=self.Entity:GetPhysicsObject()
		if phys:IsValid() then
			phys:Wake()
			phys:SetMass(250)
			phys:SetBuoyancyRatio(.3)
		end
		---
		if(IsValid(self.Owner))then
			local Tem=self.Owner:Team()
			if(Tem)then
				local Col=team.GetColor(Tem)
				--if(Col)then self:SetColor(Col) end
			end
		end
		---
		self.MaxElectricity=100
		self.MaxFuel=100
		self.EZbuildCost=JMOD_CONFIG.Blueprints["EZ Workbench"][2]
		---
		self:SetElectricity(self.MaxElectricity)
		self:SetFuel(self.MaxFuel)
	end
	function ENT:Destroy(dmginfo)
		self:EmitSound("snd_jack_turretbreak.wav",70,math.random(80,120))
		for i=1,10 do self:DamageSpark() end
		local Force=(dmginfo and dmginfo:GetDamageForce()) or (VectorRand())
		for i=1,3 do
			self:FlingProp("models/gibs/scanner_gib02.mdl",Force)
			self:FlingProp("models/gibs/scanner_gib02.mdl",Force)
			self:FlingProp("models/props_c17/oildrumchunk01d.mdl",Force)
			self:FlingProp("models/props_c17/oildrumchunk01e.mdl",Force)
			self:FlingProp("models/props_c17/oildrumchunk01e.mdl",Force)
			self:FlingProp("models/gibs/scanner_gib02.mdl",Force)
			self:FlingProp("models/gibs/scanner_gib02.mdl",Force)
		end
		self:Remove()
	end
	function ENT:PhysicsCollide(data,physobj)
		if((data.Speed>80)and(data.DeltaTime>0.2))then
			self.Entity:EmitSound("Metal_Box.ImpactHard")
			if(data.Speed>1000)then
				self:Destroy()
			end
		end
	end
	function ENT:ConsumeElectricity(amt)
		amt=(amt or .2)
		local NewAmt=math.Clamp(self:GetElectricity()-amt,0,self.MaxElectricity)
		self:SetElectricity(NewAmt)
	end
	function ENT:DamageSpark()
		local effectdata=EffectData()
		effectdata:SetOrigin(self:GetPos()+self:GetUp()*50+VectorRand()*math.random(0,30))
		effectdata:SetNormal(VectorRand())
		effectdata:SetMagnitude(math.Rand(2,4)) --amount and shoot hardness
		effectdata:SetScale(math.Rand(.5,1.5)) --length of strands
		effectdata:SetRadius(math.Rand(2,4)) --thickness of strands
		util.Effect("Sparks",effectdata,true,true)
		self:EmitSound("snd_jack_turretfizzle.wav",70,100)
		self:ConsumeElectricity(1)
	end
	function ENT:OnTakeDamage(dmginfo)
		if(self)then
			self:TakePhysicsDamage(dmginfo)
			if(dmginfo:GetDamage()>120)then self:Destroy() end
		end
	end
	function ENT:FlingProp(mdl,force)
		local Prop=ents.Create("prop_physics")
		Prop:SetPos(self:GetPos()+self:GetUp()*25+VectorRand()*math.Rand(1,25))
		Prop:SetAngles(VectorRand():Angle())
		Prop:SetModel(mdl)
		Prop:Spawn()
		Prop:Activate()
		Prop:SetCollisionGroup(COLLISION_GROUP_DEBRIS)
		constraint.NoCollide(Prop,self)
		local Phys=Prop:GetPhysicsObject()
		Phys:SetVelocity(self:GetPhysicsObject():GetVelocity()+VectorRand()*math.Rand(1,300)+self:GetUp()*100)
		Phys:AddAngleVelocity(VectorRand()*math.Rand(1,10000))
		if(force)then Phys:ApplyForceCenter(force/7) end
		SafeRemoveEntityDelayed(Prop,math.random(20,40))
	end
	function ENT:Use(activator)
		if((self:GetFuel()>0)and(self:GetElectricity()>0))then
			--
		end
	end
	function ENT:Think()
		local Time=CurTime()
		--
		self:NextThink(Time+.1)
		return true
	end
	function ENT:OnRemove()
		--
	end
	function ENT:EZsalvage()
		if(self.Salvaged)then return end
		self.Salvaged=true
		local scale,pos=2,self:GetPos()+self:GetUp()*20
		---
		local effectdata=EffectData()
		effectdata:SetOrigin(pos+VectorRand())
		effectdata:SetNormal((VectorRand()+Vector(0,0,1)):GetNormalized())
		effectdata:SetMagnitude(math.Rand(1,2)*scale*4) --amount and shoot hardness
		effectdata:SetScale(math.Rand(.5,1.5)*scale*4) --length of strands
		effectdata:SetRadius(math.Rand(2,4)*scale*4) --thickness of strands
		util.Effect("Sparks",effectdata,true,true)
		---
		sound.Play("snds_jack_gmod/ez_tools/hit.wav",pos+VectorRand(),60,math.random(80,120))
		sound.Play("snds_jack_gmod/ez_tools/"..math.random(1,27)..".wav",pos,60,math.random(80,120))
		---
		local eff=EffectData()
		eff:SetOrigin(pos+VectorRand())
		eff:SetScale(scale)
		util.Effect("eff_jack_gmod_ezbuildsmoke",eff,true,true)
		---
		for i=1,20 do
			timer.Simple(i/100,function()
				if(IsValid(self))then
					if(i<20)then
						sound.Play("snds_jack_gmod/ez_tools/"..math.random(1,27)..".wav",pos,60,math.random(80,120))
					else
						local Box=ents.Create("ent_jack_gmod_ezparts")
						Box:SetPos(pos+VectorRand()*10)
						Box:Spawn()
						Box:Activate()
						Box:SetResource(self.EZbuildCost.parts*.75)
						self:Remove()
					end
				end
			end)
		end
	end
	function ENT:TryLoadResource(typ,amt)
		if(amt<=0)then return 0 end
		if(typ=="power")then
			local Powa=self:GetElectricity()
			local Missing=self.MaxElectricity-Powa
			if(Missing<=0)then return 0 end
			if(Missing<self.MaxElectricity*.1)then return 0 end
			local Accepted=math.min(Missing,amt)
			self:SetElectricity(Powa+Accepted)
			self:EmitSound("snd_jack_turretbatteryload.wav",65,math.random(90,110))
			return math.ceil(Accepted)
		elseif(typ=="fuel")then
			local Fool=self:GetFuel()
			local Missing=self.MaxFuel-Fool
			if(Missing<=0)then return 0 end
			if(Missing<self.MaxFuel*.1)then return 0 end
			local Accepted=math.min(Missing,amt)
			self:SetFuel(Fool+Accepted)
			self:EmitSound("snds_jack_gmod/fuel_load.wav",65,math.random(90,110))
			return math.ceil(Accepted)
		end
		return 0
	end
elseif(CLIENT)then
	function ENT:Initialize()
		--self.Camera=JMod_MakeModel(self,"models/props_combine/combinecamera001.mdl")
		-- models/props_phx/construct/glass/glass_dome360.mdl
		self.MaxElectricity=100
	end
	local function ColorToVector(col)
		return Vector(col.r/255,col.g/255,col.b/255)
	end
	local DarkSprite=Material("white_square")
	function ENT:DrawTranslucent()
		local SelfPos,SelfAng,FT=self:GetPos(),self:GetAngles(),FrameTime()
		local Up,Right,Forward=SelfAng:Up(),SelfAng:Right(),SelfAng:Forward()
		---
		local BasePos=SelfPos+Up*60
		local Obscured=util.TraceLine({start=EyePos(),endpos=BasePos,filter={LocalPlayer(),self},mask=MASK_OPAQUE}).Hit
		local Closeness=LocalPlayer():GetFOV()*(EyePos():Distance(SelfPos))
		local DetailDraw=Closeness<36000 -- cutoff point is 400 units when the fov is 90 degrees
		if((not(DetailDraw))and(Obscured))then return end -- if player is far and sentry is obscured, draw nothing
		if(Obscured)then DetailDraw=false end -- if obscured, at least disable details
		---
		self:DrawModel()
		--[[ -- todo: use this in the prop conversion machines
		local Col=Color(0,0,0,50)
		render.SetMaterial(DarkSprite)
		for i=1,30 do
			render.DrawQuadEasy(BasePos+Up*(i*1.3-5),Up,38,38,Col)
		end
		--]]
		--[[
		local CamAng=SelfAng:GetCopy()
		--CamAng:RotateAroundAxis(Up,-90)
		--CamAng:RotateAroundAxis(Right,180)
		--JMod_RenderModel(self.Camera,BasePos+Up*10+Forward*25,CamAng,nil,GradeColors[Grade],GradeMats[Grade])
		
		local Matricks=Matrix()
		Matricks:Scale(Vector(.4,1.45,.5))
		self.BottomCanopy:EnableMatrix("RenderMultiply",Matricks)
		local BottomCanopyAng=SelfAng:GetCopy()
		BottomCanopyAng:RotateAroundAxis(Right,180)
		JMod_RenderModel(self.BottomCanopy,BasePos-Up*17+Right*2,BottomCanopyAng)
		
		local Opacity=math.random(50,200)
		cam.Start3D2D(BasePos+Up*22+Right*22+Forward*21,DisplayAng,.08)
		draw.SimpleTextOutlined("POWER "..math.Round(self:GetElectricity()/self.MaxElectricity*100).."%","JMod-Display",0,0,Color(255,255,255,Opacity),TEXT_ALIGN_CENTER,TEXT_ALIGN_TOP,3,Color(0,0,0,Opacity))
		draw.SimpleTextOutlined("SUPPLIES "..self:GetSupplies().."/"..self.MaxSupplies*EZ_GRADE_BUFFS[Grade],"JMod-Display",0,40,Color(255,255,255,Opacity),TEXT_ALIGN_CENTER,TEXT_ALIGN_TOP,3,Color(0,0,0,Opacity))
		cam.End3D2D()
		--]]
	end
	language.Add("ent_jack_gmod_ezworkbench","EZ Workbench")
end