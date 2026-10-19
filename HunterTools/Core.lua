local _, F = ...
F.VERSION = "3.1.4"
F.FEED_SPELL = 6991
F.FEED_EFFECT = 1539

local function public(value)
    return not issecretvalue or not issecretvalue(value)
end
F.IsPublic = public

function F.Print(message)
    DEFAULT_CHAT_FRAME:AddMessage("|cffffcc66HunterTools:|r " .. message)
end

function F.LoadSettings()
    if type(HunterToolsDB) ~= "table" then
        local function copy(value)
            if type(value)~="table" then return value end
            local result={}; for key,item in pairs(value) do result[key]=copy(item) end
            return result
        end
        HunterToolsDB=type(FeedomaticTooDB)=="table" and copy(FeedomaticTooDB) or {}
    end
    F.db = HunterToolsDB
    if type(F.db.instanceChecks)~="table" then F.db.instanceChecks={} end
    for _,key in ipairs({"growl","pack"}) do
        if type(F.db.instanceChecks[key])~="boolean" then F.db.instanceChecks[key]=true end
    end
    if type(F.db.protectQuestFood) ~= "boolean" then F.db.protectQuestFood = true end
    if F.db.foodOrder ~= "low" then F.db.foodOrder = "high" end
    if type(F.db.mute) ~= "boolean" then F.db.mute = false end
    if type(F.db.wolfSound) ~= "boolean" then F.db.wolfSound = false end
    for _, key in ipairs({"whitelist", "blacklist"}) do
        if type(F.db[key]) ~= "table" then F.db[key] = {} end
    end
    if type(F.db.enabled) ~= "boolean" then F.db.enabled = true end
    for key,default in pairs({x=0,y=-160}) do
        local n=F.db[key]
        if type(n)~="number" or n~=n or math.abs(n)>10000 then F.db[key]=default end
    end
    if F.db.textReminder ~= "off" and F.db.textReminder ~= "chat" and F.db.textReminder ~= "both" then
        F.db.textReminder = "screen"
    end
    local minutes = tonumber(F.db.reminderMinutes)
    if not minutes or minutes ~= minutes or minutes < 0 or minutes > 120 then minutes = 3 end
    F.db.reminderMinutes = minutes
    if type(F.db.showFoodCount) ~= "boolean" then F.db.showFoodCount = true end
    if type(F.db.lowFoodWarning) ~= "boolean" then F.db.lowFoodWarning = true end
    local threshold = tonumber(F.db.lowFoodThreshold)
    if not threshold or threshold ~= threshold or threshold < 0 or threshold > 999 then threshold = 10 end
    F.db.lowFoodThreshold = math.floor(threshold)
    if type(F.db.petFoodLists) ~= "table" then F.db.petFoodLists = {} end
    F.NormalizePetFoodProfiles()
    F.bagsDirty = true
    if F.LoadAmmoSettings then F.LoadAmmoSettings() end
    if F.PetStatusSettings then F.PetStatusSettings() end
end

function F.CheckAPIs()
    if not (C_PetInfo and C_PetInfo.CanPetEatItem and C_PetInfo.GetPetHappiness
        and C_Container and C_Container.GetContainerItemInfo and C_Container.GetContainerNumSlots
        and C_Item and C_Item.GetItemInfo and C_Spell and C_Spell.GetSpellTexture and C_Spell.GetSpellName
        and C_SpellBook and C_SpellBook.IsSpellKnown
        and C_UnitAuras and C_UnitAuras.GetAuraDataBySpellName) then
        return false
    end
    return true
end

-- Check lockdown FIRST. Forever can return restricted information in combat.
-- The secure visibility driver handles hiding without insecure frame writes.
function F.GetState()
    if InCombatLockdown() then return "hidden", "Combat" end
    if not F.supported then return "hidden", "Required Forever APIs unavailable" end
    local _, class = UnitClass("player")
    if class ~= "HUNTER" then return "hidden", "Hunter only" end
    if UnitIsDeadOrGhost("player") then return "hidden", "You are dead or a ghost" end
    if UnitOnTaxi("player") then return "hidden", "Flight path" end
    if IsMounted() then return "hidden", "Mounted" end
    if UnitInVehicle and UnitInVehicle("player") then return "hidden", "In a vehicle" end
    if not UnitExists("pet") then return "hidden", "No pet" end
    if UnitIsDeadOrGhost("pet") then return "hidden", "Pet is dead" end
    local _, hunterPet = HasPetUI()
    if not hunterPet then return "hidden", "No hunter pet" end
    local playerCombat, petCombat = UnitAffectingCombat("player"), UnitAffectingCombat("pet")
    if not public(playerCombat) or not public(petCombat) or playerCombat or petCombat then
        return "hidden", "You or your pet are in combat"
    end
    if not C_SpellBook.IsSpellKnown(F.FEED_SPELL) then return "hidden", "Learn Feed Pet first" end
    local happiness = C_PetInfo.GetPetHappiness()
    if not public(happiness) then return "hidden", "Pet happiness unavailable" end
    if happiness ~= 1 and happiness ~= 2 then
        return "hidden", happiness == 3 and "Pet is happy" or "Pet happiness unavailable"
    end
    local effectName = C_Spell.GetSpellName(F.FEED_EFFECT)
    if effectName then
        local aura = C_UnitAuras.GetAuraDataBySpellName("pet", effectName, "HELPFUL")
        if not public(aura) then return "hidden", "Feeding status unavailable" end
        if aura then return "hidden", "Pet is already being fed" end
    end
    if GetTime() < (F.waitUntil or 0) then return "hidden", "Waiting for feeding response" end
    if C_Spell.GetSpellCooldown then
        local cooldown = C_Spell.GetSpellCooldown(F.FEED_SPELL)
        if cooldown then
            if not public(cooldown.startTime) or not public(cooldown.duration) then
                return "hidden", "Spell cooldown unavailable"
            end
            if cooldown.startTime and cooldown.duration and cooldown.duration > 0
                and cooldown.startTime + cooldown.duration > GetTime() then
                return "hidden", "Feed Pet is on cooldown"
            end
        end
    end
    return "hungry", happiness == 1 and "Unhappy" or "Content"
end

-- Use the client's native diet/eligibility check; no English tooltip parsing
-- or incomplete item-ID whitelist. Only carried bags are scanned, never banks.
function F.CurrentPetKey()
    if InCombatLockdown and InCombatLockdown() then return nil end
    local guid=UnitGUID and UnitGUID("pet")
    if not public(guid) or type(guid)~='string' or guid=='' then return end
    local name=UnitName and UnitName('pet')
    local family=UnitCreatureFamily and UnitCreatureFamily('pet')
    if public(name) and public(family) and type(name)=='string' and name:find('%S') and type(family)=='string' and family:find('%S') then
        return F.PetFoodProfileKey(name,family)
    end
    return guid
end

function F.PetFoodProfileKey(name,family)
    return 'pet:'..name:match('^%s*(.-)%s*$'):lower()..':'..family:match('^%s*(.-)%s*$'):lower()
end

local function mergeFoodRules(target,source)
    for _,kind in ipairs({'whitelist','blacklist'}) do
        if type(target[kind])~='table' then target[kind]={} end
        if type(source[kind])=='table' then
            for id,value in pairs(source[kind]) do if value then target[kind][id]=true end end
        end
    end
end

function F.NormalizePetFoodProfiles()
    if F.db.petFoodListsVersion==3 then return end
    local normalized={}
    for key,profile in pairs(F.db.petFoodLists) do
        if type(profile)=='table' then
            local targetKey=key
            if type(profile.name)=='string' and profile.name:find('%S') and type(profile.family)=='string' and profile.family:find('%S') then
                targetKey=F.PetFoodProfileKey(profile.name,profile.family)
            end
            if normalized[targetKey] then mergeFoodRules(normalized[targetKey],profile)
            else normalized[targetKey]=profile end
        end
    end
    F.db.petFoodLists=normalized;F.db.petFoodListsVersion=3
end

function F.FoodLists(create)
    local key=F.CurrentPetKey()
    if not key then return F.db end
    F.db.petFoodLists=F.db.petFoodLists or {}
    local guid=UnitGUID and UnitGUID('pet')
    local name=UnitName and UnitName('pet')
    local family=UnitCreatureFamily and UnitCreatureFamily('pet')
    if not public(name) then name=nil end
    if not public(family) then family=nil end
    if key~=guid and public(guid) and type(F.db.petFoodLists[guid])=='table' then
        -- The exact current GUID identifies this legacy entry safely. Never
        -- infer a family from a name shared by potentially different pets.
        local legacy=F.db.petFoodLists[guid]
        if type(F.db.petFoodLists[key])=='table' then mergeFoodRules(F.db.petFoodLists[key],legacy)
        else F.db.petFoodLists[key]=legacy end
        F.db.petFoodLists[guid]=nil
    end
    local profile=F.db.petFoodLists[key]
    if type(profile)~="table" then
        F.sessionPetFoodLists=F.sessionPetFoodLists or {}
        profile=F.sessionPetFoodLists[key]
        if type(profile)~='table' then
        profile={whitelist={},blacklist={}}
        -- Preserve existing food protection as the starting point for each pet.
        for _,kind in ipairs({"whitelist","blacklist"}) do
            for id,value in pairs(F.db[kind]) do profile[kind][id]=value end
        end
        F.sessionPetFoodLists[key]=profile
        local previous=F.petFoodGuidProfiles and F.petFoodGuidProfiles[guid]
        if previous and previous.key~=key and previous.profile.family==family then
            mergeFoodRules(profile,previous.profile)
            if F.db.petFoodLists[previous.key]==previous.profile then F.db.petFoodLists[key]=profile end
        end
        end
        -- Save summoned pets only after their name and family are available.
        -- A GUID-only fallback stays transient to avoid duplicate legacy records.
        if create or key~=guid then F.db.petFoodLists[key]=profile end
    end
    for _,kind in ipairs({"whitelist","blacklist"}) do
        if type(profile[kind])~="table" then profile[kind]={} end
    end
    if public(name) and type(name)=="string" and name:find("%S") then profile.name=name end
    if type(family)=='string' and family:find('%S') then profile.family=family end
    if public(guid) and type(guid)=='string' then
        F.petFoodGuidProfiles=F.petFoodGuidProfiles or {};F.petFoodGuidProfiles[guid]={key=key,profile=profile}
    end
    return profile
end

function F.PetListDeletionBlocked(key)
    if InCombatLockdown() then return true end
    if key==F.CurrentPetKey() then return true end
    local profile=F.db.petFoodLists[key]
    local guid=UnitGUID and UnitGUID('pet')
    if not public(guid) or not guid then return false end
    if key==guid then return true end
    local name=UnitName and UnitName('pet')
    if type(profile)=='table' and not profile.family and public(name) and type(name)=='string' and type(profile.name)=='string' then
        return profile.name:lower()==name:lower()
    end
    return false
end
function F.DeletePetLists(key)
    if InCombatLockdown() then return false,"Delete lists after combat." end
    if F.PetListDeletionBlocked(key) then return false,"Dismiss or switch pets before deleting its saved lists. Unknown-family entries with your pet's name are protected too." end
    if not key or not F.db.petFoodLists[key] then return false,"No saved lists selected." end
    F.db.petFoodLists[key]=nil
    if F.sessionPetFoodLists then F.sessionPetFoodLists[key]=nil end
    for guid,entry in pairs(F.petFoodGuidProfiles or {}) do if entry.key==key then F.petFoodGuidProfiles[guid]=nil end end
    return true,"Saved pet food lists deleted."
end

function F.SavedPetListGroups()
    local byKey={}
    for key,profile in pairs(F.db.petFoodLists) do
        local name=type(profile.name)=='string' and profile.name or 'Unnamed pet'
        local family=type(profile.family)=='string' and profile.family or 'Family unknown (legacy)'
        local id=F.PetFoodProfileKey(name,family)
        local group=byKey[id]
        if not group then group={id=id,name=name,family=family,keys={},allowed=0,blocked=0};byKey[id]=group end
        group.keys[#group.keys+1]=key
        if F.PetListDeletionBlocked(key) then group.active=true end
        for _ in pairs(profile.whitelist or {}) do group.allowed=group.allowed+1 end
        for _ in pairs(profile.blacklist or {}) do group.blocked=group.blocked+1 end
    end
    local groups={};for _,group in pairs(byKey) do table.sort(group.keys);groups[#groups+1]=group end
    table.sort(groups,function(a,b) return a.id<b.id end);return groups
end
function F.InactivePetListKeys()
    local keys={}
    for key in pairs(F.db.petFoodLists) do if not F.PetListDeletionBlocked(key) then keys[#keys+1]=key end end
    table.sort(keys);return keys
end
function F.DeleteSavedPetLists(keys)
    if InCombatLockdown() then return false,'Delete lists after combat.' end
    for _,key in ipairs(keys) do
        if not F.db.petFoodLists[key] or F.PetListDeletionBlocked(key) then return false,'Selection changed or includes your current pet. Select and confirm again.' end
    end
    for _,key in ipairs(keys) do
        F.db.petFoodLists[key]=nil;if F.sessionPetFoodLists then F.sessionPetFoodLists[key]=nil end
        for guid,entry in pairs(F.petFoodGuidProfiles or {}) do if entry.key==key then F.petFoodGuidProfiles[guid]=nil end end
    end
    return true,('Deleted %d saved pet food record%s.'):format(#keys,#keys==1 and '' or 's')
end

function F.FoodAllowed(id)
    if F.FoodProtectionReason and F.FoodProtectionReason(id) then return false end
    if not F.FoodProtectionReason and F.QuestFoodReason and F.QuestFoodReason(id) then return false end
    local lists=F.FoodLists()
    if lists.blacklist[id] then return false end
    return next(lists.whitelist) == nil or lists.whitelist[id] == true
end

function F.ListCommand(text)
    local list, action, item = text:match('^%s*(%S+)%s+(%S+)%s*(.-)%s*$')
    list, action = list and list:lower(), action and action:lower()
    if list ~= 'whitelist' and list ~= 'blacklist' then return false end
    local lists=F.FoodLists(action=='add' or action=='remove' or action=='clear')
    local entries = lists[list]
    if action == 'list' then
        local ids = {}
        for id in pairs(entries) do table.insert(ids, id) end
        table.sort(ids)
        F.Print(list .. (#ids == 0 and ': empty' or ':'))
        for _, id in ipairs(ids) do
            local name = C_Item.GetItemInfo(id)
            F.Print(tostring(id) .. ' - ' .. (name or 'item name not cached'))
        end
        return true
    elseif action == 'clear' then
        lists[list] = {}
    elseif action == 'add' or action == 'remove' then
        local id = tonumber(item:match('item:(%d+)') or item:match('^(%d+)$'))
        if not id or id < 1 or id ~= math.floor(id) then
            F.Print('Use an item link or numeric item ID.'); return true
        end
        entries[id] = action == 'add' and true or nil
    else
        F.Print('/fom ' .. list .. ' add|remove <item link or ID>, list, or clear')
        return true
    end
    F.bagsDirty = true
    F.Print(list .. ' updated.' .. (next(lists.whitelist) and ' Whitelist restriction is active.' or ' Whitelist restriction is off.'))
    F.Refresh(true)
    return true
end

function F.PreferFood(food, best)
    if not best then return true end
    if food.level ~= best.level then
        if F.db.foodOrder == "low" then return food.level < best.level end
        return food.level > best.level
    end
    return food.count < best.count
end

function F.QueueFoodEntryScan()
    F.foodEntryPending=true
    F.foodEntryReadyAt=GetTime()+10
    F.foodEntrySnapshot=nil
    F.food=nil; F.foodCount=nil; F.pendingItems=true
    F.bagsDirty=true
end

function F.ConfirmFoodEntryScan(count,pending,locked)
    if not F.foodEntryPending then return end
    local now=GetTime()
    if now<F.foodEntryReadyAt or pending or locked then F.foodEntrySnapshot=nil; return end
    local pet=UnitGUID and UnitGUID('pet')
    if not public(pet) or not pet then F.foodEntrySnapshot=nil; return end
    local snapshot=F.foodEntrySnapshot
    if not snapshot or snapshot.count~=count or snapshot.pet~=pet then
        F.foodEntrySnapshot={count=count,pet=pet,at=now}; return
    end
    if now-snapshot.at<2 then return end
    F.foodEntryPending=nil; F.foodEntrySnapshot=nil
end

function F.FindFood()
    if InCombatLockdown and InCombatLockdown() then return end
    if F.ScanQuestFood then F.ScanQuestFood() end
    local best, count, pending, locked = nil, 0, false, false
    F.protectedFoodReasons={}
    for bag = 0, (NUM_TOTAL_EQUIPPED_BAG_SLOTS or NUM_BAG_SLOTS or 4) do
        local slots=C_Container.GetContainerNumSlots(bag)
        if not public(slots) or type(slots)~='number' or slots<0 then
            pending=true; slots=0
        elseif bag==0 and slots==0 then pending=true end
        for slot = 1, slots do
            local item = C_Container.GetContainerItemInfo(bag, slot)
            if item and public(item.itemID) and item.itemID and item.stackCount > 0 and F.FoodProtectionReason then
                local protection=F.FoodProtectionReason(item.itemID)
                if protection then
                    local edible=C_PetInfo.CanPetEatItem(item.itemID)
                    if public(edible) and edible then
                        F.protectedFoodReasons[protection]=(F.protectedFoodReasons[protection] or 0)+item.stackCount
                    end
                end
            end
            if item and public(item.itemID) and item.itemID and item.stackCount > 0 and F.FoodAllowed(item.itemID) then
                -- Uncached weapons, quest items and other non-food must not hold
                -- the entire food scan in a permanent loading state.
                local edible=C_PetInfo.CanPetEatItem(item.itemID)
                if not public(edible) or edible==nil then
                    pending=true
                elseif edible then
                    local name, link, quality, level = C_Item.GetItemInfo(item.itemID)
                    if not public(name) or not name then
                        pending=true -- Only edible items require food metadata.
                    elseif item.isLocked then
                        locked = true
                    else
                        count = count + item.stackCount
                        local food = {bag = bag, slot = slot, id = item.itemID, name = name,
                            link = link, level = level or 0, count = item.stackCount}
                        -- Selected item-level order, then finish a smaller stack.
                        if F.PreferFood(food, best) then
                            best = food
                        end
                    end
                end
            end
        end
    end
    F.food, F.foodCount = best, count
    F.pendingItems, F.lockedFood, F.bagsDirty = pending, locked, false
    F.ConfirmFoodEntryScan(count,pending,locked)
    return best
end

function F.Disarm()
    if not F.button or InCombatLockdown() then return end
    F.button:SetAttribute("type1", nil)
    F.button:SetAttribute("spell1", nil)
    F.button:SetAttribute("target-bag1", nil)
    F.button:SetAttribute("target-slot1", nil)
end

-- Client sound paths; no audio assets are distributed with the addon.
local wolfSound = 564228
local familySounds = {
    ["Bat"] = 548729,
    ["Bear"] = 544952,
    ["Boar"] = 545133,
    ["Cat"] = 562388,
    ["Carrion Bird"] = 545936,
    ["Crab"] = 546431,
    ["Crocolisk"] = 544941,
    ["Gorilla"] = 550959,
    ["Hyena"] = 552343,
    ["Owl"] = 557971,
    ["Raptor"] = 558875,
    ["Scorpid"] = 560306,
    ["Spider"] = 561418,
    ["Tallstrider"] = 561393,
    ["Turtle"] = 559875,
    ["Wind Serpent"] = 564132,
}
function F.HungerSoundPath()
    if F.db.mute or InCombatLockdown() then return nil end
    if F.db.wolfSound then return wolfSound end
    local family = UnitCreatureFamily and UnitCreatureFamily("pet")
    local sound = public(family) and family and familySounds[family]
    return sound or wolfSound
end

function F.PlayHungerSound(report)
    local sound = F.HungerSoundPath()
    if not sound then
        if report then F.Print(F.db.mute and "Hunger sounds are muted." or "Test sound after combat.") end
        return false
    end
    local played = PlaySoundFile(sound, "Master")
    if not played and sound ~= wolfSound then played = PlaySoundFile(wolfSound, "Master") end
    if report then
        F.Print(played and "Sound playback accepted. If silent, check WoW master volume and your system audio output."
            or "The client could not play the pet or wolf sound.")
    end
    return played == true
end

-- One alert per hunger episode, with a minimum one-minute gap.
function F.CheckHungerSound(state, reason)
    if InCombatLockdown() or not F.db.enabled then return end
    local pet=UnitGUID and UnitGUID('pet')
    if public(pet) and pet~=F.hungerSoundPet then
        F.hungerSoundPet=pet;F.hungerAlerted=false;F.lastGrowl=nil
    end
    if reason == "Pet is happy" or reason == "No pet" or reason == "Pet is dead" then
        F.hungerAlerted = false
    end
    if state ~= "hungry" or F.hungerAlerted then return end
    local now = GetTime()
    if F.lastGrowl and now - F.lastGrowl < 60 then return end
    F.hungerAlerted = true
    F.lastGrowl = now
    F.PlayHungerSound()
end

-- Local notifications only; never sends to any player or channel.
function F.ReminderPetName()
    if InCombatLockdown() then return "Your pet" end
    local name = UnitName and UnitName("pet")
    if public(name) and type(name) == "string" and name:find("%S") then return name end
    return "Your pet"
end

function F.HungerMessage()
    local name = F.ReminderPetName()
    if F.food then return name..' is hungry.' end
    if F.pendingItems then return name..' is hungry. Food inventory is still loading.' end
    if F.lockedFood then return name..' is hungry. Suitable food is temporarily locked.' end
    if F.foodEntryPending then return name..' is hungry.' end
    if not F.food and not F.pendingItems and not F.lockedFood then
        return name .. " is hungry - no suitable, allowed food in your bags."
    end
    return name .. " is hungry."
end

function F.ShowTextReminder(test)
    local mode = F.db.textReminder
    if mode == "off" then
        if test then F.Print("Text reminders are off.") end
        return
    end
    local message = test and (F.ReminderPetName() .. " is hungry. (Test reminder)") or F.HungerMessage()
    local screen = mode == "screen" or mode == "both"
    local chat = mode == "chat" or mode == "both"
    if screen and RaidNotice_AddMessage and RaidWarningFrame then
        RaidNotice_AddMessage(RaidWarningFrame, message, {r=1,g=0.8,b=0.2}, 5)
    elseif screen then
        chat = true -- Keep the reminder usable if this client's notice UI is unavailable.
    end
    if chat then F.Print(message) end
end

function F.CheckTextReminder(state, reason)
    if InCombatLockdown() or not F.db.enabled then return end
    if reason == "Pet is happy" or reason == "No pet" or reason == "Pet is dead" then
        F.lastTextReminder = nil
        F.reminderPet = nil
        return
    end
    if state ~= "hungry" or F.db.textReminder == "off" then return end
    if UnitGUID then
        local pet = UnitGUID("pet")
        if not public(pet) then return end
        if pet ~= F.reminderPet then F.lastTextReminder=nil; F.reminderPet=pet end
    end
    local now = GetTime()
    local interval = F.db.reminderMinutes * 60
    if F.lastTextReminder and (interval == 0 or now - F.lastTextReminder < interval) then return end
    F.lastTextReminder = now
    F.ShowTextReminder()
end

function F.HungerAlertStatus()
    if InCombatLockdown() then return 'Hunger alerts paused: combat.' end
    if not F.db.enabled then return 'Hunger alerts paused: Pet feeding is disabled in the tools menu.' end
    local state,reason=F.GetState()
    local channel=F.db.textReminder or 'off'
    if state~='hungry' then return 'Hunger alerts paused: '..tostring(reason)..'. Text reminders: '..channel..'.' end
    if channel=='off' then return 'Pet is hungry. Text reminders are off; hunger sound '..(F.db.mute and 'is muted.' or 'is enabled.') end
    local pet=UnitGUID and UnitGUID('pet')
    local seconds=0
    if public(pet) and pet==F.reminderPet and F.lastTextReminder then
        if F.db.reminderMinutes==0 then return 'Pet is hungry. Reminder already sent; repeats are set to once per hunger episode.' end
        seconds=math.max(0,math.ceil(F.db.reminderMinutes*60-(GetTime()-F.lastTextReminder)))
    end
    return 'Pet is hungry. Text reminders: '..channel..'. '..(seconds>0 and ('Next reminder in '..seconds..' seconds.') or 'Reminder is due.')
end
function F.DebugHungerAlerts()
    F.Print(F.HungerAlertStatus())
    F.Print('Inventory loading: '..tostring(F.foodEntryPending or F.pendingItems or false)..'; sound muted: '..tostring(F.db.mute)..'; sound already sent: '..tostring(F.hungerAlerted or false)..'.')
end

function F.WhyThisFood()
    if InCombatLockdown and InCombatLockdown() then return nil end
    if not F.food or (F.mode ~= "food" and F.reason ~= "Pet is happy") then return nil end
    return ("Why this food? %s is allowed by your lists, unlocked, and edible by your pet. " ..
        "Its item level (%d) ranks %s among available choices. Equal levels use the smaller stack (%d here); " ..
        "equal stacks use bag order. This ranks item level, not price or measured happiness.%s"):format(
        F.food.name, F.food.level or 0, F.db.foodOrder == "low" and "lowest" or "highest", F.food.count or 0,
        F.pendingItems and " Some item information is still loading." or "")
end

-- Count only allowed, edible, unlocked items from the current bag scan.
function F.SupplyCountText()
    if not F.db.showFoodCount then return "" end
    if F.reason ~= "Pet is happy" and F.mode ~= "food" and F.mode ~= "nofood" then return "" end
    if F.foodCount == nil then return "" end
    return tostring(F.foodCount) .. ((F.pendingItems or F.lockedFood) and "+" or "")
end

function F.CheckLowFood(state, reason)
    if InCombatLockdown() or not F.db.enabled then return end
    if F.foodEntryPending then return end
    if reason == "No pet" or reason == "Pet is dead" or reason == "Hunter only" then
        F.lowFoodPet=nil; F.lowFoodAlerted=nil; return
    end
    if state ~= "hungry" and reason ~= "Pet is happy" then return end
    local pet = UnitGUID and UnitGUID("pet")
    if not public(pet) or not pet then return end
    if pet ~= F.lowFoodPet then F.lowFoodPet=pet; F.lowFoodAlerted=nil end
    if not F.db.lowFoodWarning then F.lowFoodAlerted=nil; return end
    if F.pendingItems or F.lockedFood or F.foodCount == nil then return end
    if F.foodCount > F.db.lowFoodThreshold then F.lowFoodAlerted=nil; return end
    if F.lowFoodAlerted then return end
    F.lowFoodAlerted=true
    local name=F.ReminderPetName()
    if F.foodCount == 0 then
        F.Print(name .. " has no suitable, allowed food left. Stock up before heading out.")
    else
        F.Print(("%s has %d food item%s left. Stock up before heading out."):format(
            name, F.foodCount, F.foodCount == 1 and "" or "s"))
    end
end

function F.Refresh(forceScan)
    if not F.button or InCombatLockdown() or F.clickInProgress then return end
    if F.dragging then F.Disarm(); return end
    F.FoodLists()
    if not F.db.enabled then F.Disarm(); F.button:Hide(); return end
    if F.foodEntryPending then forceScan=true end
    local state, reason = F.GetState()
    F.reason = reason
    F.CheckHungerSound(state, reason)
    F.Disarm()
    if reason == "Hunter only" then F.button:Hide(); return end
    if reason == "Pet is happy" and (forceScan or F.bagsDirty) then F.FindFood() end
    if state ~= "hungry" then F.CheckLowFood(state, reason); F.CheckTextReminder(state, reason); F.Render("hidden"); return end
    if forceScan or F.bagsDirty then F.FindFood() end
    F.CheckLowFood(state, reason)
    F.CheckTextReminder(state, reason)
    if F.food then
        local b = F.button
        b:SetAttribute("spell1", F.FEED_SPELL)
        b:SetAttribute("target-bag1", F.food.bag)
        b:SetAttribute("target-slot1", F.food.slot)
        b:SetAttribute("type1", "spell")
        F.Render("food")
    elseif F.pendingItems or F.lockedFood then
        -- Loading or temporarily locked items are not evidence of having no food.
        F.reason = F.pendingItems and "Loading food information" or "Food temporarily locked"
        F.Render("hidden")
    else
        F.Render("nofood")
    end
end

function F.FoodPreview()
    if InCombatLockdown() or F.reason ~= "Pet is happy" then return nil end
    if F.food then return "Next food: " .. F.food.name end
    if F.pendingItems then return "Loading food information..." end
    if F.lockedFood then return "Suitable food is temporarily locked." end
    return "No allowed, suitable unlocked food in your bags."
end

function F.TooltipStatus()
    if InCombatLockdown() then return "Feeding unavailable during combat." end
    if F.mode == "food" and F.food then return "Click to feed: " .. F.food.name end
    if F.mode == "nofood" then
        local reasons={}
        for reason,count in pairs(F.protectedFoodReasons or {}) do reasons[#reasons+1]=reason.." ("..count..")" end
        table.sort(reasons)
        if #reasons>0 then return "Food excluded by protection: "..table.concat(reasons,", ")..". Open Food > Food protection to change it." end
        return "No allowed, suitable unlocked food in your bags."
    end
    if F.reason == "Pet is happy" then return "Your pet is happy; feeding is not needed." end
    local explanations={
        ["No pet"]="Summon your pet to feed it.",
        ["Pet is dead"]="Revive your pet before feeding.",
        ["Pet is already being fed"]="Feeding in progress; wait for the feeding effect to finish.",
        ["Mounted"]="Dismount to feed your pet.",
        ["Flight path"]="Feeding resumes after your flight.",
        ["In a vehicle"]="Leave the vehicle to feed your pet.",
        ["Learn Feed Pet first"]="Learn Feed Pet from your hunter trainer.",
        ["You are dead or a ghost"]="Return to life before feeding your pet.",
        ["Waiting for feeding response"]="Waiting for the game to confirm feeding.",
        ["Loading food information"]="Food details are loading; selection will update when ready.",
        ["Food temporarily locked"]="Suitable food is being moved or used; wait for it to unlock.",
        ["Feed Pet is on cooldown"]="Feed Pet is on cooldown; wait before feeding again.",
        ["You or your pet are in combat"]="Feeding resumes when you and your pet leave combat.",
    }
    return explanations[F.reason] or F.reason or "Waiting for pet information."
end

function F.PreClick(_, mouseButton)
    if InCombatLockdown() then return end
    F.pendingFeedNotice=nil
    -- Re-read the bags immediately before the protected click. A bag sort, trade,
    -- sold stack or different pet must never leave the old slot armed.
    F.Refresh(true)
    local blocked=mouseButton ~= "LeftButton" or IsShiftKeyDown() or F.dragging
        or GetTime() < (F.dragStoppedAt or -1) + 0.3
        or (SpellIsTargeting and SpellIsTargeting())
        or (GetCursorInfo and GetCursorInfo())
    if blocked then
        F.Disarm()
    elseif F.mode=='food' and F.food and public(F.food.name) and type(F.food.name)=='string' then
        local pet=UnitGUID and UnitGUID('pet')
        if public(pet) and pet then
            F.pendingFeedNotice={pet=pet,name=F.ReminderPetName(),food=F.food.name,at=GetTime()}
        end
    end
    -- Synchronous spell/bag events can run inside the protected click. Keep its
    -- item-target attributes intact until Blizzard finishes the whole action.
    F.clickInProgress = true
end

function F.HandleFeedCastEvent(event,unit,spellID)
    if not public(unit) or not public(spellID) or unit~='player' or spellID~=F.FEED_SPELL then return end
    local notice=F.pendingFeedNotice
    F.pendingFeedNotice=nil
    if event~='UNIT_SPELLCAST_SUCCEEDED' then return end
    F.waitUntil=GetTime()+1
    if not notice or GetTime()-notice.at>5 or InCombatLockdown() then return end
    local pet=UnitGUID and UnitGUID('pet')
    if not public(pet) or pet~=notice.pet then return end
    local timestamp=time and time()
    if public(timestamp) and type(timestamp)=='number' then
        F.db.petLastFeeds=type(F.db.petLastFeeds)=='table' and F.db.petLastFeeds or {}
        F.db.petLastFeeds[pet]={food=notice.food,at=timestamp}
    end
    F.Print('Fed '..notice.name..' a delicious '..notice.food)
end

function F.PostClick(_, mouseButton)
    F.clickInProgress = false
    if InCombatLockdown() then return end
    F.Refresh()
    if mouseButton == "RightButton" then F.OpenConfig() end
end


function F.PetDietText()
    if InCombatLockdown() then return "Pet diet: unavailable during combat." end
    if not UnitExists("pet") then return "Pet diet: summon a pet to see its food types." end
    local getTypes = C_PetInfo and C_PetInfo.GetPetFoodTypes or GetPetFoodTypes
    if not getTypes then return "Pet diet information unavailable." end
    local values = {getTypes()}
    if not public(values[1]) then return "Pet diet information unavailable." end
    if type(values[1]) == "table" then values = values[1] end
    local names = {}
    for _, value in ipairs(values) do
        if public(value) and type(value) == "string" and value ~= "" then
            table.insert(names, value)
        end
    end
    return #names > 0 and ("Pet eats: " .. table.concat(names, ", ")) or "Pet diet information unavailable."
end

function F.NoFoodTint(mode)
    return mode == "nofood" or (F.reason == "Pet is happy" and not F.bagsDirty
        and not F.food and not F.pendingItems and not F.lockedFood)
end
