--[[-----------------------------------------------------------------

    Neal's Clock v 2.1

    Copyright (c) 2008, Anton I. (Neavx @ Alleria-EU)
    All rights reserved.

    Modified by sixue @ USTCBBS, 2018

--]]-----------------------------------------------------------------

local SORT_BY_NAME = false
local ANCHORPOINT = "BOTTOMLEFT"
local CLOCK_WIDTH = 360
local CLOCK_HEIGHT = 52
local CLOCK_AZERITE_HEIGHT = 20
local CLOCK_BAR_HEIGHT = 3

    --========[ important functions ]========--

local function Addoncompare(a, b)
    return a.memory > b.memory
end

local function MemFormat(v)
    if (v > 1024) then
        return string.format("%.2f MiB", v / 1024)
    else
        return string.format("%.2f KiB", v)
    end
end

local function ColorGradient(perc, ...)
	if (perc > 1) then
		local r, g, b = select(select('#', ...) - 2, ...)
		return r, g, b
	elseif (perc < 0) then
		local r, g, b = ...
		return r, g, b
	end
	
	local num = select('#', ...) / 3

	local segment, relperc = math.modf(perc*(num-1))
	local r1, g1, b1, r2, g2, b2 = select((segment*3)+1, ...)

	return r1 + (r2-r1)*relperc, g1 + (g2-g1)*relperc, b1 + (b2-b1)*relperc
end

local function TimeFormat(time)
	local t = format("%.1ds",floor(mod(time,60)))
	if (time > 60) then
		time = floor(time / 60)
		t = format("%.1dm ",mod(time,60))..t
		if (time > 60) then
			time = floor(time / 60)
			t = format("%.1dh ",mod(time,24))..t
			if (time > 24) then
				time = floor(time / 24)
				t = format("%dd ",time)..t
			end
		end
	end
	return t
end

local function ColorizeLatency(v)
    if (v < 100) then
        return {r = 0, g = 1, b = 0}
    elseif (v < 300) then
        return {r = 1, g = 1, b = 0}
    else
        return {r = 1, g = 0, b = 0}
    end
end

local function ColorizeFramerate(v)
    if (v < 10) then
        return {r = 1, g = 0, b = 0}
    elseif (v < 30) then
        return {r = 1, g = 0.5, b = 0}
    elseif (v < 60) then
        return {r = 1, g = 1, b = 0}
    else
        return {r = 0, g = 1, b = 0}
    end
end

local function ColorizeLatency2(v)
    if (v < 100) then
        return "00ff00"
    elseif (v < 300) then
        return "ffff00"
    else
        return "ff0000"
    end
end

local function ColorizeFramerate2(v)
    if (v < 10) then
        return "ff0000"
    elseif (v < 30) then
        return "ff8000"
    elseif (v < 60) then
        return "ffff00"
    else
        return "00ff00"
    end
end

    --========[ frames ]========--

local class_color = RAID_CLASS_COLORS[select(2, UnitClass("player"))]

local nClock = CreateFrame("Frame", "nClock", UIParent)
nClock:SetPoint(ANCHORPOINT, UIParent)
nClock:SetHeight(CLOCK_HEIGHT)
nClock:SetWidth(CLOCK_WIDTH)
nClock:SetMovable(true)
nClock:SetUserPlaced(true)

local bg = nClock:CreateTexture(nil, "BACKGROUND")
bg:SetAllPoints(nClock)
bg:SetColorTexture(0, 0, 0, 0.5)

local bar0 = nClock:CreateTexture(nil, "BACKGROUND")
bar0:SetPoint("TOPLEFT", nClock)
bar0:SetHeight(CLOCK_AZERITE_HEIGHT)
bar0:SetWidth(CLOCK_WIDTH)
bar0:SetColorTexture(0.6, 0.5, 0.3, 0.9)

local bar1 = nClock:CreateTexture(nil, "BACKGROUND")
bar1:SetPoint("TOPLEFT", bar0, "BOTTOMLEFT")
bar1:SetHeight(CLOCK_BAR_HEIGHT)
bar1:SetWidth(CLOCK_WIDTH / 3)

local bar2 = nClock:CreateTexture(nil, "BACKGROUND")
bar2:SetPoint("TOPLEFT", bar1, "TOPRIGHT")
bar2:SetHeight(CLOCK_BAR_HEIGHT)
bar2:SetWidth(CLOCK_WIDTH / 3)

local bar3 = nClock:CreateTexture(nil, "BACKGROUND")
bar3:SetPoint("TOPLEFT", bar2, "TOPRIGHT")
bar3:SetHeight(CLOCK_BAR_HEIGHT)
bar3:SetWidth(CLOCK_WIDTH / 3)

local text0 = nClock:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
text0:SetAllPoints(bar0)
text0:SetShadowOffset(1, 1)
text0:SetTextColor(1, 1, 1)

local text1 = nClock:CreateFontString(nil, "ARTWORK", "GameFontNormal")
text1:SetPoint("TOPLEFT", bar1, "BOTTOMLEFT", 0, -3)
text1:SetShadowOffset(1, -1)
text1:SetTextColor(1, 1, 1)

local text2 = nClock:CreateFontString(nil, "ARTWORK", "GameFontNormal")
text2:SetPoint("TOPLEFT", bar2, "BOTTOMLEFT", 0, -3)
text2:SetShadowOffset(1, -1)
text2:SetTextColor(1, 1, 1)

local text3 = nClock:CreateFontString(nil, "ARTWORK", "GameFontNormal")
text3:SetPoint("TOPLEFT", bar3, "BOTTOMLEFT", 0, -3)
text3:SetShadowOffset(1, -1)
text3:SetTextColor(1, 1, 1)

    --========[ update ]========--

local lastUpdate = 0
local updateDelay = 1
nClock:SetScript("OnUpdate", function(self, elapsed)
    lastUpdate = lastUpdate + elapsed
    if (lastUpdate > updateDelay) then
        lastUpdate = 0

        if C_AzeriteItem.HasActiveAzeriteItem() then
            local aLoc = C_AzeriteItem.FindActiveAzeriteItem()
            local xp, totalLevelXP = C_AzeriteItem.GetAzeriteItemXPInfo(aLoc)
            text0:SetText("  Azerite Energy: "..xp.."/"..totalLevelXP.."  ")
            text0:Show()
            bar0:Show()
            
        elseif HasArtifactEquipped() then
            local _, _, _, _, totalXP, pointsSpent, _, _, _, _, _, _, artifactTier = C_ArtifactUI.GetEquippedArtifactInfo()
            local _, xp, xpForNextPoint = ArtifactBarGetNumArtifactTraitsPurchasableFromXP(pointsSpent, totalXP, artifactTier)
            xp = xpForNextPoint == 0 and 0 or xp
            text0:SetText("  Artifact Energy: "..xp.."/"..xpForNextPoint.."  ")
            text0:Show()
            bar0:Show()

        else
            text0:Hide()
            bar0:Hide()

        end

		fps = GetFramerate()

        fpscolor = ColorizeFramerate(floor(fps))
        bar1:SetColorTexture(fpscolor.r, fpscolor.g, fpscolor.b, 0.9)
        text1:SetText("  FPS: |cff"..ColorizeFramerate2(floor(fps))..floor(fps).."|r Hz  ")

        local _,_,home,world = GetNetStats()

        homelagcolor = ColorizeLatency(home)
        bar2:SetColorTexture(homelagcolor.r, homelagcolor.g, homelagcolor.b, 0.9)
        text2:SetText("  HOME: |cff"..ColorizeLatency2(tonumber(home))..home.."|r ms  ")

        worldlagcolor = ColorizeLatency(world)
        bar3:SetColorTexture(worldlagcolor.r, worldlagcolor.g, worldlagcolor.b, 0.9)
        text3:SetText("  WORLD: |cff"..ColorizeLatency2(tonumber(world))..world.."|r ms  ")
    end
end)

    --========[ make the frame movable ]========--
  
nClock:SetScript("OnMouseDown", function()
    if (IsAltKeyDown()) then
        nClock:ClearAllPoints()
        nClock:StartMoving()
    end
end)
nClock:SetScript("OnMouseUp", function()
    nClock:StopMovingOrSizing()
end)

    --========[ tooltip ]========--

nClock:SetScript("OnEnter", function()
    GameTooltip:SetOwner(nClock, "ANCHOR_TOPLEFT", 2, 5)
    collectgarbage()
    local memory, i, addons, total, entry, total
    local latency3color = ColorizeLatency(select(3, GetNetStats()))
    local latency4color = ColorizeLatency(select(4, GetNetStats()))
    local fpscolor = ColorizeFramerate(GetFramerate())
        
    GameTooltip:AddLine(date("%A, %d %B, %Y"), 1, 1, 1)
    GameTooltip:AddDoubleLine("Framerate:", format("%.1f Hz", GetFramerate()), 1, 1, 1, fpscolor.r, fpscolor.g, fpscolor.b)
    GameTooltip:AddDoubleLine("Latency HOME:", format("%d ms", select(3, GetNetStats())), 1, 1, 1, latency3color.r, latency3color.g, latency3color.b)
    GameTooltip:AddDoubleLine("Latency WORLD:", format("%d ms", select(4, GetNetStats())), 1, 1, 1, latency4color.r, latency4color.g, latency4color.b)
    GameTooltip:AddDoubleLine("System Uptime:", TimeFormat(GetTime()), 1, 1, 1, 1, 1, 1)
 	GameTooltip:AddDoubleLine(". . . . . . . . . . .", ". . . . . . . . . . .", 1, 1, 1, 1, 1, 1)

    addons = {}
    total = 0
    UpdateAddOnMemoryUsage()
    for i = 1, GetNumAddOns(), 1 do
        if GetAddOnMemoryUsage(i) > 0 then
            memory = GetAddOnMemoryUsage(i)
            entry = {name = GetAddOnInfo(i), memory = memory}
            table.insert(addons, entry)
            total = total + memory
        end
    end
    
    if (SORT_BY_NAME == false) then 
        table.sort(addons, Addoncompare)
    end

   for _,entry in pairs(addons) do
		local cr, cg, cb = ColorGradient((entry.memory / 800), 0, 1, 0, 1, 1, 0, 1, 0, 0)
		GameTooltip:AddDoubleLine(entry.name, MemFormat(entry.memory), 1, 1, 1, cr, cg, cb)
	end
    local cr, cg, cb = ColorGradient((entry.memory / 800), 0, 1, 0, 1, 1, 0, 1, 0, 0) 
    GameTooltip:AddDoubleLine(". . . . . . . . . . .", ". . . . . . . . . . .", 1, 1, 1, 1, 1, 1)
    GameTooltip:AddDoubleLine("Total", MemFormat(total), 1, 1, 1, cr, cg, cb)
    GameTooltip:AddDoubleLine("..with Blizzard", MemFormat(collectgarbage("count")), 1, 1, 1, cr, cg, cb)
    GameTooltip:Show()
end)

nClock:SetScript("OnLeave", function() 
    GameTooltip:Hide() 
end)

    --========[ mem cleanup ]========--

-- nClock:SetScript("OnClick", function()
--     if (not IsAltKeyDown()) then
--         UpdateAddOnMemoryUsage()
--         local memBefore = gcinfo()
--         collectgarbage()
--         UpdateAddOnMemoryUsage()
--         local memAfter = gcinfo()
--         DEFAULT_CHAT_FRAME:AddMessage("Memory cleaned: |cff00FF00"..MemFormat(memBefore - memAfter))
--     end
-- end)