--[[
-- Kui_Nameplates
-- By Kesava at curse.com
-- All rights reserved
-- Backported by: Kader at github.com/bkader
]]
local kui = LibStub("Kui-1.0")
local addon = LibStub("AceAddon-3.0"):GetAddon("KuiNameplates")
local mod = addon:NewModule("Castbar", addon.Prototype, "AceEvent-3.0")
local L = LibStub("AceLocale-3.0"):GetLocale("KuiNameplates")

mod.uiName = L["Cast bars"]

local castbarsByUnit = {}
local format = format
local function ResetFade(f)
	if not f or not f.castbar then
		return
	end

	kui.frameFadeRemoveFrame(f.castbar)
	f.castbar.shield:Hide()
	f.castbar:Hide()
	f.castbar:SetAlpha(1)
end

local sizes = {}

local function SetCVars()
	-- force these to true as the module hides them anyway
	SetCVar("showVKeyCastbar", 1)
end
------------------------------------------------------------- Script handlers --
local function OnCastbarUpdate(unit, isChannel)
	if not mod.enabledState then
		return
	end

	local f = C_NamePlate.GetNamePlateForUnit(unit).kui

	if mod:FrameIsIgnored(f) then
		return
	end

	local name, _, text, texture, startTime, endTime, _, _, notInterruptible
	if isChannel then
		name, _, text, texture, startTime, endTime, _, notInterruptible = UnitChannelInfo(unit)
	else
		name, _, text, texture, startTime, endTime, _, _, notInterruptible = UnitCastingInfo(unit)
	end

	if not name then
		f.castbar:Hide()
		return false
	end

	local currentTime = GetTime()
	local maxCastTime = (endTime - startTime) / 1000
	local elapsedTime = currentTime - (startTime / 1000)
	local remainingTime = (endTime / 1000) - currentTime

	if f.castbar.curr then
		if isChannel then
			f.castbar.curr:SetText(format("%.1f", remainingTime))
		else
			f.castbar.curr:SetText(format("%.1f", maxCastTime - elapsedTime))
		end
	end

	if f.castbar.name then
		f.castbar.name:SetText(name)
	end

	f.castbar.bar:SetMinMaxValues(0, maxCastTime)
	if isChannel then
		f.castbar.bar:SetValue(remainingTime)
	else
		f.castbar.bar:SetValue(elapsedTime)
	end

	if notInterruptible then
		f.castbar.bar:SetStatusBarColor(unpack(mod.db.profile.display.shieldbarcolour))
		f.castbar.shield:Show()
	else
		f.castbar.bar:SetStatusBarColor(unpack(mod.db.profile.display.barcolour))
		f.castbar.shield:Hide()
	end

	if f.trivial then
		-- hide text & icon
		if f.castbar.icon or f.castbar.curr then
			f.castbar.curr:Hide()
		end
	else
		if f.castbar.icon then
			f.castbar.icon.tex:SetTexture(texture)
			f.castbar.icon:Show()
		end

		if f.castbar.curr then
			f.castbar.curr:Show()
		end
	end

	f.castbar:Show()
end
local function OnEvent(self, event, unit, ...)
	if event == "PLAYER_ENTERING_WORLD" then
		if not _G["WKUI_PlayerEnteredWorld"] then
			_G["WKUI_PlayerEnteredWorld"] = true
		end
	elseif event == "NAME_PLATE_UNIT_ADDED" then
		local namePlate = C_NamePlate.GetNamePlateForUnit(unit)
		if namePlate then
			if not namePlate.kui then
				return false
			end
			local CastBar = castbarsByUnit[unit]
			if not castbarsByUnit[unit] then
				castbarsByUnit[unit] = mod:CreateCastbar(namePlate.kui)
			end

			if UnitCastingInfo(unit) or UnitChannelInfo(unit) then
				castbarsByUnit[unit]:Show()
				OnCastbarUpdate(unit, UnitChannelInfo(unit) ~= nil)
			end
		end
	elseif event == "NAME_PLATE_UNIT_REMOVED" then
		if castbarsByUnit[unit] then
			castbarsByUnit[unit]:Hide()
			castbarsByUnit[unit] = nil
		end
	elseif
		event == "UNIT_SPELLCAST_START"
		or event == "UNIT_SPELLCAST_DELAYED"
		or event == "UNIT_SPELLCAST_CHANNEL_START"
		or event == "UNIT_SPELLCAST_CHANNEL_UPDATE"
	then
		if castbarsByUnit[unit] then
			local isChannel = (event == "UNIT_SPELLCAST_CHANNEL_START" or event == "UNIT_SPELLCAST_CHANNEL_UPDATE")

			castbarsByUnit[unit]:Show()
			OnCastbarUpdate(unit, isChannel)
		end
	elseif
		event == "UNIT_SPELLCAST_INTERRUPTED"
		or event == "UNIT_SPELLCAST_STOP"
		or event == "UNIT_SPELLCAST_FAILED"
	then
		if castbarsByUnit[unit] then
			castbarsByUnit[unit]:Hide()
		end
	elseif event == "UNIT_SPELLCAST_SUCCEEDED" then
		-- typically we do nothing special; the castbar fades on its own
	end
end
---------------------------------------------------------------------- create --
-- update castbar height and icon size
local function UpdateCastbar(frame)
	if not frame.castbar then
		return
	end

	if frame.castbar.bg then
		frame.castbar.bg:SetHeight(sizes.cbheight)
	end

	if frame.castbar.icon then
		frame.castbar.icon.bg:SetSize(sizes.icon, sizes.icon)
	end
end
function mod:CreateCastbar(frame)
	if frame.castbar then
		return frame.castbar
	end
	-- container ---------------------------------------------------------------
	frame.castbar = CreateFrame("Frame", nil, frame)
	frame.castbar:SetFrameLevel(1)
	frame.castbar:Hide()

	-- background --------------------------------------------------------------
	frame.castbar.bg = frame.castbar:CreateTexture(nil, "ARTWORK", nil, 1)
	frame.castbar.bg:SetTexture(kui.m.t.solid)
	frame.castbar.bg:SetVertexColor(0, 0, 0, 0.8)

	frame.castbar.bg:SetPoint("TOPLEFT", frame.bg.fill, "BOTTOMLEFT", 0, -1)
	frame.castbar.bg:SetPoint("TOPRIGHT", frame.bg.fill, "BOTTOMRIGHT", 0, 0)

	-- cast bar ------------------------------------------------------------
	frame.castbar.bar = CreateFrame("StatusBar", nil, frame.castbar)
	frame.castbar.bar:SetStatusBarTexture(addon.bartexture)
	frame.castbar.bar:GetStatusBarTexture():SetDrawLayer("ARTWORK", 2)

	frame.castbar.bar:SetPoint("TOPLEFT", frame.castbar.bg, "TOPLEFT", 1, -1)
	frame.castbar.bar:SetPoint("BOTTOMLEFT", frame.castbar.bg, "BOTTOMLEFT", 1, 1)
	frame.castbar.bar:SetPoint("RIGHT", frame.castbar.bg, "RIGHT", -1, 0)

	frame.castbar.bar:SetMinMaxValues(0, 1)

	-- spark
	frame.castbar.spark = frame.castbar.bar:CreateTexture(nil, "ARTWORK")
	frame.castbar.spark:SetDrawLayer("ARTWORK", 6)
	frame.castbar.spark:SetVertexColor(1, 1, 0.8)
	frame.castbar.spark:SetTexture("Interface\\AddOns\\Kui_Nameplates\\Media\\t\\spark")
	frame.castbar.spark:SetPoint("TOP", frame.castbar.bar:GetRegions(), "TOPRIGHT", 0, 3)
	frame.castbar.spark:SetPoint("BOTTOM", frame.castbar.bar:GetRegions(), "BOTTOMRIGHT", 0, -3)
	frame.castbar.spark:SetWidth(6)

	-- uninterruptible cast shield -----------------------------------------
	frame.castbar.shield = frame.castbar.bar:CreateTexture(nil, "ARTWORK")
	frame.castbar.shield:SetTexture("Interface\\AddOns\\Kui_Nameplates\\Media\\Shield")
	frame.castbar.shield:SetTexCoord(0, 0.84375, 0, 1)
	frame.castbar.shield:SetVertexColor(0.5, 0.5, 0.7)

	frame.castbar.shield:SetSize(sizes.shield * 0.84375, sizes.shield)
	frame.castbar.shield:SetPoint("LEFT", frame.castbar.bg, -7, 0)

	frame.castbar.shield:SetBlendMode("BLEND")
	frame.castbar.shield:SetDrawLayer("ARTWORK", 7)

	frame.castbar.shield:Hide()

	-- cast bar text -------------------------------------------------------
	if self.db.profile.display.spellname then
		frame.castbar.name = frame:CreateFontString(frame.castbar.bar, { size = "small" })
		frame.castbar.name:SetPoint("TOP", frame.castbar.bar, "BOTTOM", 0, -3)
	end

	if self.db.profile.display.casttime then
		frame.castbar.curr = frame:CreateFontString(frame.castbar.bar, { size = "small" })
		frame.castbar.curr:SetPoint("LEFT", frame.castbar.bg, "RIGHT", 2, 0)
	end

	if self.db.profile.display.spellicon then
		frame.castbar.icon = CreateFrame("Frame", nil, frame.castbar)

		frame.castbar.icon.bg = frame.castbar:CreateTexture(nil, "BACKGROUND")
		frame.castbar.icon.bg:SetTexture(kui.m.t.solid)
		frame.castbar.icon.bg:SetVertexColor(0, 0, 0, 0)
		frame.castbar.icon.bg:SetPoint("TOPRIGHT", frame.health, "TOPLEFT", -2, 1)

		frame.castbar.icon.tex = frame.castbar:CreateTexture(nil, "ARTWORK")
		frame.castbar.icon.tex:SetPoint("TOPLEFT", frame.castbar.icon.bg, "TOPLEFT", 1, -1)
		frame.castbar.icon.tex:SetPoint("BOTTOMRIGHT", frame.castbar.icon.bg, "BOTTOMRIGHT", -1, 1)
	end

	UpdateCastbar(frame)

	return frame.castbar
end
------------------------------------------------------------------------ Hide --
function mod:HideCastbar(frame)
	ResetFade(frame)
end
------------------------------------------------------------------- Functions --
function mod:FrameIsIgnored(frame)
	return frame.castbar_ignore_frame or (frame.friend and not self.db.profile.onfriendly)
end
function mod:IgnoreFrame(frame)
	frame.castbar_ignore_frame = (frame.castbar_ignore_frame and frame.castbar_ignore_frame + 1 or 1)

	if frame.castbar and frame.castbar:IsShown() then
		ResetFade(frame)
	end
end
function mod:UnignoreFrame(frame)
	frame.castbar_ignore_frame = (frame.castbar_ignore_frame and frame.castbar_ignore_frame - 1 or nil)
	if frame.castbar_ignore_frame and frame.castbar_ignore_frame <= 0 then
		frame.castbar_ignore_frame = nil
	end
end
---------------------------------------------------- Post db change functions --
mod:AddConfigChanged("enabled", function(v)
	mod:Toggle(v)
end)
mod:AddConfigChanged({ "display", "shieldbarcolour" }, nil, function(f, v)
	f.castbar.shield:SetVertexColor(unpack(v))
end)
mod:AddConfigChanged({ "display", "cbheight" }, function()
	sizes.cbheight = mod.db.profile.display.cbheight
	sizes.icon = addon.db.profile.general.hheight + sizes.cbheight + 1
end, UpdateCastbar)
mod:AddConfigChanged({ "updateinterval" }, function(v)
	mod.updateInterval = v
end)
mod:AddGlobalConfigChanged("addon", { "general", "hheight" }, mod.configChangedFuncs.display.cbheight.ro, UpdateCastbar)
-------------------------------------------------------------------- Register --
function mod:GetOptions()
	return {
		enabled = {
			type = "toggle",
			name = L["Enable cast bar"],
			desc = L["Show cast bars (at all)"],
			order = 0,
			disabled = false,
		},
		onfriendly = {
			type = "toggle",
			name = L["Show friendly cast bars"],
			desc = L["Show cast bars on friendly nameplates"],
			order = 10,
			disabled = function()
				return not self.db.profile.enabled
			end,
		},
		display = {
			type = "group",
			name = L["Display"],
			inline = true,
			order = 20,
			disabled = function()
				return not self.db.profile.enabled
			end,
			args = {
				casttime = {
					type = "toggle",
					name = L["Show cast time"],
					desc = L["Show cast time and time remaining"],
					order = 20,
				},
				spellname = {
					type = "toggle",
					name = L["Show spell name"],
					order = 15,
				},
				spellicon = {
					type = "toggle",
					name = L["Show spell icon"],
					order = 10,
				},
				barcolour = {
					type = "color",
					name = L["Bar colour"],
					desc = L["The colour of the cast bar during interruptible casts"],
					order = 0,
				},
				shieldbarcolour = {
					type = "color",
					name = L["Uninterruptible colour"],
					desc = L["The colour of the cast bar and shield during UNinterruptible casts."],
					order = 5,
				},
				cbheight = {
					type = "range",
					name = L["Height"],
					desc = L["The height of castbars on nameplates. Also affects the size of the spell icon."],
					order = 25,
					step = 1,
					min = 3,
					softMax = 20,
					max = 100,
				},
			},
		},
		updateinterval = {
			type = "range",
			name = L["Update Interval"],
			desc = L["How often the cast bar updates. Lower values make it smoother, but may affect performance"],
			order = 30,
			step = 0.01,
			min = 0.01,
			softMax = 0.05,
			max = 1,
		},
	}
end
function mod:OnInitialize()
	self.db = addon.db:RegisterNamespace(self.moduleName, {
		profile = {
			enabled = true,
			onfriendly = true,
			updateinterval = 0.01,
			display = {
				casttime = false,
				spellname = true,
				spellicon = true,
				cbheight = 5,
				barcolour = { 0.43, 0.47, 0.55, 1 },
				shieldbarcolour = { 0.8, 0.1, 0.1, 1 },
			},
		},
	})

	addon:InitModuleOptions(self)
	self:SetEnabledState(self.db.profile.enabled)

	sizes = { cbheight = self.db.profile.display.cbheight, shield = 16 }
    mod.updateInterval = self.db.profile.updateinterval
	self.configChangedFuncs.display.cbheight.ro(sizes.cbheight)

	-- handle default interface cvars & checkboxes
	InterfaceOptionsCombatPanel:HookScript("OnShow", function()
		InterfaceOptionsCombatPanelEnemyCastBarsOnNameplates:SetChecked(true)
		InterfaceOptionsCombatPanelEnemyCastBarsOnNameplates:Disable()
	end)
	InterfaceOptionsFrame:HookScript("OnHide", function()
		SetCVars()
	end)

	SetCVars()
end
function mod:OnEnable()
	local EventFrame = CreateFrame("Frame")
	EventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
	EventFrame:RegisterEvent("NAME_PLATE_UNIT_ADDED")
	EventFrame:RegisterEvent("NAME_PLATE_UNIT_REMOVED")
	EventFrame:RegisterEvent("UNIT_SPELLCAST_START")
	EventFrame:RegisterEvent("UNIT_SPELLCAST_DELAYED")
	EventFrame:RegisterEvent("UNIT_SPELLCAST_CHANNEL_START")
	EventFrame:RegisterEvent("UNIT_SPELLCAST_CHANNEL_UPDATE")
	EventFrame:RegisterEvent("UNIT_SPELLCAST_INTERRUPTED")
	EventFrame:RegisterEvent("UNIT_SPELLCAST_STOP")
	EventFrame:RegisterEvent("UNIT_SPELLCAST_FAILED")
	EventFrame:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")

	EventFrame:SetScript("OnEvent", OnEvent)

	local timeSinceLastUpdate = 0

	EventFrame:SetScript("OnUpdate", function(self, elapsed)
		timeSinceLastUpdate = timeSinceLastUpdate + elapsed
		if timeSinceLastUpdate >= mod.updateInterval then
			for unit, CastBar in pairs(castbarsByUnit) do
				if CastBar:IsShown() then
					local isChannel = (UnitChannelInfo(unit) ~= nil)
					OnCastbarUpdate(unit, isChannel)
				end
			end
			timeSinceLastUpdate = 0
		end
	end)
end
function mod:OnDisable()
	for _, frame in pairs(addon.frameList) do
		self:HideCastbar(frame.kui)
	end

	if self.EventFrame then
		self.EventFrame:SetScript("OnEvent", nil)
		self.EventFrame:SetScript("OnUpdate", nil)
		self.EventFrame:UnregisterAllEvents()
	end
end
