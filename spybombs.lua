--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--
-- file:    spybombs.lua
-- brief:
-- author:  Leonid Krashenko <leonid.krashenko@gmail.com>
--
-- Copyright (C) 2014.
-- Licensed under the terms of the GNU GPL, v2.
--
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
function widget:GetInfo()
	return {
		name = "Spy Bombs",
		desc = "Tells spy-bots to destroy themselfs if there is enemy crowd nearby.",
		author = "jetbird",
		date = "Apr 19, 2015",
		license = "GNU GPL, v2",
		layer = 0,
		enabled = true --  loaded by default?
	}
end


local glColor = gl.Color
local glDepthTest = gl.DepthTest
local glBeginEnd = gl.BeginEnd
local glLineWidth = gl.LineWidth
local glShape = gl.Shape
local glDrawGroundCircle = gl.DrawGroundCircle
local GetUnitDefID = Spring.GetUnitDefID
local spGetAllUnits = Spring.GetAllUnits
local spGetSpectatingState = Spring.GetSpectatingState
local spGetMyPlayerID = Spring.GetMyPlayerID
local spGetPlayerInfo = Spring.GetPlayerInfo
local spGetMyTeamID = Spring.GetMyTeamID
local spGetTeamUnits = Spring.GetTeamUnits
local spGetUnitDefID = Spring.GetUnitDefID
local spGiveOrderToUnitMap = Spring.GiveOrderToUnitMap
local spGetGroundInfo = Spring.GetGroundInfo
local spGetGroundHeight = Spring.GetGroundHeight
local spGetUnitsInCylinder = Spring.GetUnitsInCylinder
local echo = Spring.Echo

local units = {} -- player's units
local armSpyUDId = UnitDefNames["armspy"].id
local coreSpyUDId = UnitDefNames["corspy"].id
local targets = {}
local spyTimeToBlast = {}


--[[
function widget:DrawWorldPreUnit()
	glLineWidth(3.0)
	glDepthTest(true)
	glColor(1, 0, 0, .2)
	for id, v in pairs(units) do
		local posx,posy,posz = Spring.GetUnitPosition(id)
		gl.Color(0.5, 0.5, 0.5, 0.5);
		gl.DrawGroundCircle(posx, posy, posz, v, 25)
	end

	glDepthTest(false)
end
--]]
--[[
function widget:DrawScreenEffects()
	
    for id, v in pairs(units) do
        local x,y=Spring.WorldToScreenCoords(Spring.GetUnitPosition(id))
		local time = spyTimeToBlast[id]
		if time == nil then time = "" end
        gl.Text("ID:"..v..": ".." -- "..time,x,y,16,"od")
    end
end
--]]

local function dispatchUnit(unitID, unitDefID)
	--local ud = UnitDefs[unitDefID]
	if unitDefID == armSpyUDId or unitDefID == coreSpyUDId then
		local udef = UnitDefs[unitDefID]
		local selfdBlastId = WeaponDefNames[string.lower(udef["selfDExplosion"])].id
		local selfdBlastRadius = WeaponDefs[selfdBlastId]["damageAreaOfEffect"]
		units[unitID] = selfdBlastRadius
		spyTimeToBlast[unitID] = 0
		--echo ("spy detected "..selfdBlastRadius)
	end
end

function widget:Update(dt)
	for id, v in pairs(units) do
		local posx,posy,posz = Spring.GetUnitPosition(id)
		targets[id] = Spring.GetUnitsInSphere(posx, posy, posz, v)
		
		local enemies = 0
		for _, tid in ipairs(targets[id]) do
			if Spring.GetUnitTeam(tid) ~= spGetMyTeamID() then
				enemies = enemies + 1
			end
		end
		
		if enemies > 2 then
			spyTimeToBlast[id] = spyTimeToBlast[id] + dt
			if spyTimeToBlast[id] > 0.5 then 
				Spring.GiveOrderToUnit(id, CMD.SELFD, {}, {})
				units[id] = nil
				spyTimeToBlast[id] = nil
			end
		else
			spyTimeToBlast[id] = 0
		end
		
	end

end

function widget:UnitFinished(unitID, unitDefID, unitTeam)
	if (unitTeam ~= spGetMyTeamID()) then
		return
	end
	dispatchUnit(unitID, unitDefID)
end

function widget:UnitDestroyed(unitID, unitDefID, unitTeam)
	units[unitID] = nil
end


function widget:UnitTaken(unitID, unitDefID, unitTeam, newTeam)
	widget:UnitDestroyed(unitID, unitDefID)
end


function widget:UnitGiven(unitID, unitDefID, unitTeam, oldTeam)
	widget:UnitFinished(unitID, unitDefID, unitTeam)
end


function widget:Initialize()
																																						
	local playerID = spGetMyPlayerID()
	local _, _, spec, _, _, _, _, _ = spGetPlayerInfo(playerID)
	if spec == true then
		Spring.Echo("<Spy Bombs> Spectator mode. Widget removed")
		widgetHandler:RemoveWidget(self)
	end

	local allunits = spGetTeamUnits(spGetMyTeamID())
	for _, uid in ipairs(allunits) do
		dispatchUnit(uid, spGetUnitDefID(uid))
	end
end

