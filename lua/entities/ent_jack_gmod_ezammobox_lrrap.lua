-- Jackarunda 2020
AddCSLuaFile()
ENT.Base="ent_jack_gmod_ezammobox"
ENT.PrintName="EZ Light Rifle Round - Armor Piercing"
ENT.Spawnable=false -- soon(tm)
ENT.Category="JMod - EZ Ammo Types"
ENT.EZammo="Light Rifle Round - Armor Piercing"
---
if(SERVER)then
	--
elseif(CLIENT)then
	language.Add(ENT.ClassName,ENT.PrintName)
end