--[[
-- Kui_Nameplates
-- By Kesava at curse.com
-- All rights reserved
-- Backported by: Kader at https://github.com/bkader
--
-- Provides class colors for friendly targets
]]
local addon = LibStub("AceAddon-3.0"):GetAddon("KuiNameplates")
local mod = addon:NewModule("ClassColors", addon.Prototype, "AceEvent-3.0")
local L = LibStub("AceLocale-3.0"):GetLocale("KuiNameplates")

local select, GetPlayerInfoByGUID, tinsert = select, GetPlayerInfoByGUID, tinsert

local cc_table

mod.uiName = L["Class colors"]

local function SetCVars()
	SetCVar("ShowClassColorInNameplate", mod.db.profile.enemy and 1 or 0)
end
-- functions ###################################################################
function mod:SetClassColor(frame, cc)
	frame.name.class_colored = true
	frame.name:SetTextColor(cc.r, cc.g, cc.b)
end
-- message handlers ############################################################
function mod:GUIDAssumed(msg, f)
	if not (f.friend and f.player and f.guid) then
		return
	end
	local class = select(2, GetPlayerInfoByGUID(f.guid))
	if not class then
		return
	end

	self:SetClassColor(f, cc_table[class])
end
function mod:PostShow(msg, f)
	if not (f.friend and f.player) then
		return
	end
	-- a friendly player; make their name slightly gray
	-- will be overwritten when GUIDStored/Assumed fires
	f.name:SetTextColor(.7, .7, .7)
end
function mod:PostHide(msg, f)
	f.name.class_colored = nil
	f.name:SetTextColor(1, 1, 1, 1)
end
-- config changed hooks ########################################################
mod:AddConfigChanged(
	"friendly",
	function(v)
		if v then
			mod:Enable()
		else
			mod:Disable()
		end
	end,
	function(f, v)
		if v then
			mod:PostShow(nil, f)
		else
			mod:PostHide(nil, f)
		end
	end
)
mod:AddConfigChanged("enemy", function(v) SetCVars() end)
-- config hooks ################################################################
function mod:GetOptions()
	return {
		friendly = {
			type = "toggle",
			name = L["Class color friendly player names"],
			desc = L["Class color the names of friendly players and dim the names of friendly players with no class information. Note that friendly players will only become class colored once you mouse over their frames, at which point their class will be cached."],
			width = "double",
			order = 10
		},
		enemy = {
			type = "toggle",
			name = L["Class color hostile players' health bars"],
			desc = L["Class color the health bars of hostile players, where they are attackable. This is a default interface option."],
			width = "double",
			order = 20
		}
	}
end
function mod:OnInitialize()
	cc_table = CUSTOM_CLASS_COLORS or RAID_CLASS_COLORS
	self.db = addon.db:RegisterNamespace(self.moduleName, {profile = {friendly = true, enemy = true}})

	addon:InitModuleOptions(self)
	self:SetEnabledState(self.db.profile.friendly)

	-- handle default interface cvars & checkboxes
	InterfaceOptionsCombatPanel:HookScript("OnShow", function()
		InterfaceOptionsCombatPanelNameplateClassColors:Disable()
		InterfaceOptionsCombatPanelNameplateClassColors:SetChecked(mod.db.profile.enemy)
		InterfaceOptionsCombatPanelNameplateClassColors.Enable = function() return end
	end)
	InterfaceOptionsFrame:HookScript("OnHide", function() SetCVars() end)
	SetCVars()
end
function mod:OnEnable()
	self:RegisterMessage("KuiNameplates_GUIDAssumed", "GUIDAssumed")
	self:RegisterMessage("KuiNameplates_GUIDStored", "GUIDAssumed")
	self:RegisterMessage("KuiNameplates_PostShow", "PostShow")
	self:RegisterMessage("KuiNameplates_PostHide", "PostHide")
end
function mod:OnDisable()
	self:UnregisterMessage("KuiNameplates_GUIDAssumed")
	self:UnregisterMessage("KuiNameplates_GUIDStored")
	self:UnregisterMessage("KuiNameplates_PostShow")
	self:UnregisterMessage("KuiNameplates_PostHide")
end