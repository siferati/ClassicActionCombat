--- SLASH COMMANDS ---

SLASH_CAC1 = "/cac"
SlashCmdList["CAC"] = function(msg)
	local cmd, arg1, arg2 = strsplit(" ", msg, 3)

	-- /cac reset
	if cmd == "reset" then
		CAC_Settings = nil
	
	-- /cac show windows
	elseif cmd == "show" and arg1 == "windows" then
		foreach(CAC_Settings.windows, print)

	-- /cac add window <name>
	elseif cmd == "add" and arg1 == "window" and arg2 then
		for i = 1, #CAC_Settings.windows do
			if CAC_Settings.windows[i] == arg2 then
				return print(arg2 .. " is already part of the windows list.")
			end
		end
		table.insert(CAC_Settings.windows, arg2)
		table.sort(CAC_Settings.windows)
		print(arg2 .. " added to the windows list.")
	
	-- /cac remove window <name>
	elseif cmd == "remove" and arg1 == "window" and arg2 then
		for i = 1, #CAC_Settings.windows do
			if CAC_Settings.windows[i] == arg2 then
				table.remove(CAC_Settings.windows, i)
				return print(arg2 .. " removed from the windows list.")
			end
		end
		print("No window of name " .. arg2 .. " was found.")

	-- /cac show keybinds
	elseif cmd == "show" and arg1 == "keybinds" then	
		print("Classic Action Combat Keybinds:")
		print("----------")
		print("TOGGLE : " .. CAC_Settings.keybinds.TOGGLE)
		print("INTERACT : " .. CAC_Settings.keybinds.INTERACT)
		print("----------")
		print("BUTTON1 : " .. CAC_Settings.keybinds.mouse["BUTTON1"])
		print("SHIFT-BUTTON1 : " .. CAC_Settings.keybinds.mouse["SHIFT-BUTTON1"])
		print("CTRL-BUTTON1 : " .. CAC_Settings.keybinds.mouse["CTRL-BUTTON1"])
		print("----------")
		print("BUTTON2 : " .. CAC_Settings.keybinds.mouse["BUTTON2"])
		print("SHIFT-BUTTON2 : " .. CAC_Settings.keybinds.mouse["SHIFT-BUTTON2"])
		print("CTRL-BUTTON2 : " .. CAC_Settings.keybinds.mouse["CTRL-BUTTON2"])
	
	-- /cac bind <key> <binding>
	elseif cmd == "bind" and arg2 and 
			(arg1 == "BUTTON1" or arg1 == "SHIFT-BUTTON1" or arg1 == "CTRL-BUTTON1" or
			arg1 == "BUTTON2" or arg1 == "SHIFT-BUTTON2" or arg1 == "CTRL-BUTTON2") then
		CAC_Settings.keybinds.mouse[arg1] = arg2

	-- /cac bind TOGGLE <key>
	elseif cmd == "bind" and arg2 and arg1 == "TOGGLE" then
		CAC_Settings.keybinds.TOGGLE = arg2

	-- /cac bind INTERACT <key>
	elseif cmd == "bind" and arg2 and arg1 == "INTERACT" then
		CAC_Settings.keybinds.INTERACT = arg2
		
	-- error
	else
		print("Error: invalid syntax.")
	end

	-- needed for keybinds to update
	if cmd == "reset" or cmd == "bind" then
		C_UI.Reload()
	end
end


--- VARIABLES ---

-- how many times to update per second
local ups = 15

-- time since the last update
local timeSinceLastUpdate = 0

-- values: UNBOUND, BUTTON, INTERACT, INTERACT_HOSTILE
local interactKeyBinding = "UNBOUND"

-- macro to run when interact button is pressed
local interactMacro = ""

-- values: ON, OFF, PAUSE
local mouselookState = "OFF"

-- the last hostile unit {guid, name, time} that was targeted
local lastHostile = nil

-- array of NPCs {guid, name, time} with visible nameplates
local npcs = {}

-- button used for interacting
local interactBtn = CreateFrame("BUTTON", "InteractBtn", UIParent, "SecureActionButtonTemplate")
interactBtn:SetAttribute("type", "macro")

-- message shown on the screen when interacting
local interactMsg = UIParent:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
interactMsg.text = ""
interactMsg:SetPoint("BOTTOM", 0, GetScreenHeight() / 5)
interactMsg:Hide()

-- used to handle events
local mainFrame = CreateFrame("FRAME")

-- holds all event handlers
local eventHandlers = {}


--- FUNCTIONS ---

-- sets the binding for the interact key
local function setInteractKeyBinding(binding)
	if binding == interactKeyBinding then
		return
	end

	if binding == "UNBOUND" then
		SetBinding(CAC_Settings.keybinds.INTERACT, "NONE")
	elseif binding == "BUTTON" then
		SetBinding(CAC_Settings.keybinds.INTERACT, "CLICK InteractBtn:LeftButton")
	elseif binding == "INTERACT" then
		SetBinding(CAC_Settings.keybinds.INTERACT, "INTERACTTARGET")
	elseif binding == "INTERACT_HOSTILE" then
		SetBinding(CAC_Settings.keybinds.INTERACT, "TARGETLASTHOSTILE")
	end

	interactKeyBinding = binding
end


-- sets the macro for the interact button
local function setInteractMacro(macro)
	if macro == interactMacro then
		return
	end

	interactBtn:SetAttribute("macrotext", macro)
	interactMacro = macro
end


-- sets the text for the interact message
local function setInteractMsg(text)
	if text == interactMsg.text then
		return
	end
	
	interactMsg:SetText("(" .. CAC_Settings.keybinds.INTERACT .. ") " .. text)
	interactMsg.text = text
end


-- toggles mouselook
function eventHandlers.MODIFIER_STATE_CHANGED(key, down)
	if key ~= CAC_Settings.keybinds.TOGGLE or down ~= 0 then
		return
	end

	if mouselookState == "OFF" or mouselookState == "PAUSE" then
		mouselookState = "ON"
		MouselookStart()
	elseif mouselookState == "ON" then
		mouselookState = "OFF"
		MouselookStop()
	end
end


-- unbinds interaction key since it's not useful during combat
function eventHandlers.PLAYER_REGEN_DISABLED()
	setInteractKeyBinding("UNBOUND")
	if interactMsg:IsVisible() then interactMsg:Hide() end
end


-- updates last hostile target
function eventHandlers.PLAYER_TARGET_CHANGED()
	if UnitExists("target") and not UnitIsFriend("player", "target") then
		lastHostile = {
			guid = UnitGUID("target"),
			name = UnitName("target")
		}
	end
end


-- stores new NPC
function eventHandlers.NAME_PLATE_UNIT_ADDED(unitId)
	local guid = UnitGUID(unitId)
	local name = UnitName(unitId)

	-- only interested in NPCs
	if strsplit("-", guid, 2) == "Creature" and UnitIsFriend("player", unitId) then
		table.insert(npcs, {
			guid = guid,
			name = name
		})
	end
end


-- removes old NPC
function eventHandlers.NAME_PLATE_UNIT_REMOVED(unitId)
	local guid = UnitGUID(unitId)
	local name = UnitName(unitId)
	for i = 1, #npcs do
		if npcs[i].guid == guid then
			table.remove(npcs, i)
			return
		end
	end
end


-- loads settings
function eventHandlers.ADDON_LOADED(name)
	if name ~= "ClassicActionCombat" then
		return
	end

	-- defaults
	if not CAC_Settings then
		CAC_Settings = {
			keybinds = {
				mouse = {
					["BUTTON1"] = "STARTATTACK",
					["SHIFT-BUTTON1"] = "NONE",
					["CTRL-BUTTON1"] = "NONE",
					["BUTTON2"] = "TARGETSCANENEMY",
					["SHIFT-BUTTON2"] = "NONE",
					["CTRL-BUTTON2"] = "NONE"
				},
				INTERACT = "F",
				TOGGLE = "LALT"
			},
			windows = {
				"AuctionFrame", "AddonList", "BankFrame", "CharacterFrame", "ContainerFrame1", "FriendsFrame", "GameMenuFrame", "GossipFrame", "GwBagFrame", "GwBankFrame", "GwLockHudButton", "GwQuestviewFrame", "GwSettingsWindow", "HelpFrame", "InspectFrame", "InterfaceOptionsFrame", "KeyBindingFrame", "MacroFrame", "MailFrame", "MAOptions", "MerchantFrame", "QuestLogFrame", "StaticPopup1", "SpellBookFrame", "TalentFrame", "TaxiFrame", "TradeFrame", "VideoOptionsFrame", "WorldMapFrame"
			}
		}
	end

	-- override mouse keybinds while mouselooking
	for key, binding in pairs(CAC_Settings.keybinds.mouse) do
		SetMouselookOverrideBinding(key, binding)
	end
end


--- MAIN ---

-- listen to events
mainFrame:SetScript("OnEvent", function(_, event, ...)
	eventHandlers[event](...)
end)
mainFrame:RegisterEvent("MODIFIER_STATE_CHANGED")
mainFrame:RegisterEvent("NAME_PLATE_UNIT_ADDED")
mainFrame:RegisterEvent("NAME_PLATE_UNIT_REMOVED")
mainFrame:RegisterEvent("PLAYER_REGEN_DISABLED")
mainFrame:RegisterEvent("PLAYER_TARGET_CHANGED")
mainFrame:RegisterEvent("ADDON_LOADED")

-- update
mainFrame:SetScript("OnUpdate", function(_, elapsed)

	-- only update every so often
	timeSinceLastUpdate = timeSinceLastUpdate + elapsed
	if timeSinceLastUpdate < 1 / ups then
		return
	else
		timeSinceLastUpdate = timeSinceLastUpdate % (1 / ups)
	end
	
	-- true if there is a new window open
	local isNewWindowOpen = false

	-- true if there is at least one window open
	local isAnyWindowOpen = false

	-- check for windows that should pause mouselook
	for i = 1, #CAC_Settings.windows do
		local window = _G[CAC_Settings.windows[i]]

		-- why does Lua not have a continue statement ;-;
		if window then
			-- window closed
			if not window:IsVisible() then
				window.active = nil

			-- new window open
			elseif not window.active then
				window.active = true
				isNewWindowOpen = true
				isAnyWindowOpen = true
				break

			-- old window open
			else
				isAnyWindowOpen = true
			end
		end
	end

	-- pause mouselook if needed
	if mouselookState == "ON" and isNewWindowOpen then
		mouselookState = "PAUSE"
		MouselookStop() 
	elseif mouselookState == "PAUSE" and not isAnyWindowOpen then
		mouselookState = "ON"
		MouselookStart()
	end

	-- can't change keybinds nor macros during combat
	if InCombatLockdown() then return end

	-- check for npcs in range
	for i = 1, #npcs do
		local npc = npcs[i]
		
		-- if it's in range to loot, then it's in range to interact 
		if select(2, CanLootUnit(npc.guid)) then
			npc.time = npc.time or GetTime()
		else
			npc.time = nil
		end
	end

	-- sort by most recent npc in range
	table.sort(npcs, function(npc1, npc2)
		return (npc1.time or 0) > (npc2.time or 0)
	end)

	-- unit {guid, name, time, type} that became in range most recently
	local unit = npcs[1]
	if unit then unit.type = "npc" end

	-- check if there's a mob to loot or pickpocket nearby
	if lastHostile then
		local hasLoot, canLoot = CanLootUnit(lastHostile.guid)
		local canPickpocket = IsStealthed() and IsSpellInRange("Pick Pocket", "target")

		-- check if can loot or pickpocket
		if (hasLoot and canLoot) or canPickpocket == 1 then
			lastHostile.time = lastHostile.time or GetTime()

			-- check if it is more recent than npc
			if not unit or not unit.time or unit.time < lastHostile.time then
				unit = lastHostile

				if hasLoot then
					unit.type = "loot"
				elseif canPickpocket then
					unit.type = "pickpocket"
				end
			end
		else
			lastHostile.time = nil
		end
	end

	-- there's an interactable unit in range
	if unit and unit.time then
		
		-- interact
		if UnitGUID("target") == unit.guid then

			if unit.type == "pickpocket" then
				setInteractMsg("Pick Pocket")
				setInteractMacro("/cast Pick Pocket")
				setInteractKeyBinding("BUTTON")

			elseif unit.type == "npc" then
				setInteractMsg("Interact")
				setInteractKeyBinding("INTERACT")
					
			elseif unit.type == "loot" then
				setInteractMsg("Loot")
				setInteractKeyBinding("INTERACT")
			end

		-- select
		else
			setInteractMsg(unit.name)

			if unit.type == "npc" then
				setInteractMacro("/targetexact " .. unit.name)
				setInteractKeyBinding("BUTTON")

			elseif unit.type == "loot" then
				setInteractKeyBinding("INTERACT_HOSTILE")
			end
		end

		-- show interact message on screen
		if not interactMsg:IsVisible() then interactMsg:Show() end

	-- no unit in range to interact with
	else
		setInteractKeyBinding("BUTTON")
		setInteractMacro("/cleartarget")

		-- hide interact message
		if interactMsg:IsVisible() then interactMsg:Hide() end
	end
end)
