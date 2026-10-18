local addonName, F = ...
BINDING_HEADER_GFWFOREVER = 'HunterTools'
_G['BINDING_NAME_CLICK GFWForeverFeedButton:LeftButton'] = 'Feed Pet'

function F.UpdateHappinessBorder()
    if not F.button or not F.button.border then return end
    local r,g,b=0.45,0.45,0.45
    -- Do not read restricted pet data during combat.
    if not InCombatLockdown() and F.supported and UnitExists('pet') and not UnitIsDeadOrGhost('pet') then
        local happiness=C_PetInfo.GetPetHappiness()
        if F.IsPublic(happiness) then
            if happiness==3 then r,g,b=0.15,0.9,0.25
            elseif happiness==2 then r,g,b=1,0.8,0.1
            elseif happiness==1 then r,g,b=1,0.15,0.1 end
        end
    end
    for _,edge in ipairs(F.button.border) do edge:SetColorTexture(r,g,b,1) end
end

function F.Render(mode)
    F.mode=mode
    F.UpdateHappinessBorder()
    local food=mode=='food'
    F.button.icon:SetDesaturated(not food)
    if F.NoFoodTint(mode) then
        F.button.icon:SetVertexColor(1,0.15,0.15)
    else
        F.button.icon:SetVertexColor(1,1,1)
    end
    F.button.label:SetText(food and tostring(F.foodCount)..' food' or (mode=='hidden' and F.TooltipStatus() or 'No suitable food'))
    if F.button.supply then F.button.supply:SetText(F.SupplyCountText()) end
    F.button:Show()
end

function F.BuildUI()
    local gate=CreateFrame('Frame',nil,UIParent,'SecureHandlerStateTemplate')
    gate:SetAllPoints(UIParent)
    local b=CreateFrame('Button','GFWForeverFeedButton',gate,'SecureActionButtonTemplate,SecureHandlerStateTemplate')
    F.button=b
    b:SetSize(44,44)
    b:SetPoint('CENTER',UIParent,'CENTER',F.db.x,F.db.y)
    b:SetMovable(true)
    b:SetClampedToScreen(true)
    b:RegisterForDrag('LeftButton')
    b:SetAttribute('shift-type1','')
    b:SetAttribute('_onstate-combat', [[
        if newstate == 'combat' then self:SetAttribute('type1', nil) end
    ]])
    RegisterStateDriver(b,'combat','[combat] combat; peace')
    b:SetScript('OnDragStart',function()
        if InCombatLockdown() or not IsShiftKeyDown() then return end
        F.dragging=true; F.Disarm(); b:StartMoving()
    end)
    b:SetScript('OnDragStop',function()
        if InCombatLockdown() then return end
        b:StopMovingOrSizing()
        local x,y=b:GetCenter()
        local px,py=UIParent:GetCenter()
        F.db.x,F.db.y=x-px,y-py
        F.dragging=false; F.dragStoppedAt=GetTime()
        F.Refresh()
    end)
    b:RegisterForClicks('LeftButtonUp','RightButtonUp')
    b:SetAttribute('useOnKeyDown',false)
    b.icon=b:CreateTexture(nil,'ARTWORK')
    b.icon:SetAllPoints()
    b.icon:SetTexture(C_Spell.GetSpellTexture(F.FEED_SPELL))
    b.border={}
    for _,side in ipairs({'TOP','BOTTOM','LEFT','RIGHT'}) do
        local edge=b:CreateTexture(nil,'OVERLAY')
        if side=='TOP' or side=='BOTTOM' then
            edge:SetPoint(side..'LEFT',b,side..'LEFT',0,0)
            edge:SetPoint(side..'RIGHT',b,side..'RIGHT',0,0)
            edge:SetHeight(3)
        else
            edge:SetPoint('TOP'..side,b,'TOP'..side,0,0)
            edge:SetPoint('BOTTOM'..side,b,'BOTTOM'..side,0,0)
            edge:SetWidth(3)
        end
        table.insert(b.border,edge)
    end
    b.supply=b:CreateFontString(nil,'OVERLAY','NumberFontNormal')
    b.supply:SetPoint('BOTTOMRIGHT',b,'BOTTOMRIGHT',-4,4)
    b.label=b:CreateFontString(nil,'OVERLAY','GameFontNormalSmall')
    b.label:SetPoint('TOP',b,'BOTTOM',0,-4)
    b:SetHighlightTexture('Interface\\Buttons\\ButtonHilight-Square','ADD')
    b:SetScript('PreClick',F.PreClick)
    b:SetScript('PostClick',F.PostClick)
    b:SetScript('OnEnter',function()
        F.Refresh()
        GameTooltip:SetOwner(b,'ANCHOR_RIGHT')
        GameTooltip:SetText('HunterTools')
        GameTooltip:AddLine(F.TooltipStatus(),1,1,1,true)
        GameTooltip:AddLine(F.PetDietText(),0.7,0.9,1,true)
        local preview=F.FoodPreview()
        if preview then GameTooltip:AddLine(preview,0.7,0.9,0.7,true) end
        local why=F.WhyThisFood()
        if why then GameTooltip:AddLine(why,1,0.85,0.5,true) end
        GameTooltip:AddLine('Right-click: settings (Food, Instance, Ammo)',0.7,0.7,0.7)
        GameTooltip:AddLine('Border: green = happy, yellow = content, red = unhappy.',0.7,0.7,0.7,true)
        GameTooltip:AddLine('Shift-drag to move. /ht off to hide.',0.7,0.7,0.7)
        GameTooltip:Show()
    end)
    b:SetScript('OnLeave',function() GameTooltip:Hide() end)
    b:SetScript('OnHide',function() GameTooltip:Hide() end)
    b:Hide()
end

local loader=CreateFrame('Frame')
loader:RegisterEvent('ADDON_LOADED')
loader:SetScript('OnEvent',function(_,event,a,b,c)
    if event=='ADDON_LOADED' then
        if a~=addonName then return end
        loader:UnregisterEvent('ADDON_LOADED')
        F.LoadSettings()
        F.ReplayPetAbilityLearning()
        SLASH_FEEDOMATICTOO1='/ht'
        SLASH_FEEDOMATICTOO3='/fom'
        SLASH_FEEDOMATICTOO4='/huntertools'
        SLASH_FEEDOMATICTOO2='/feedomatictoo'
        SlashCmdList.FEEDOMATICTOO=function(text)
            if (text or ''):lower():match('^%s*petalertdebug%s*$') then F.DebugPetAlerts();return end
            if (text or ''):lower():match('^%s*petalerts%s*$') then F.OpenPetAlertSettings();return end
            if (text or ''):lower():match('^%s*tracking%s*$') then F.OpenTrackingSettings();return end
            if (text or ''):lower():match('^%s*aspects%s*$') then F.OpenAspectSettings();return end
            if (text or ''):lower():match('^%s*hungerdebug%s*$') then F.DebugHungerAlerts();return end
            if (text or ''):lower():match('^%s*beasts%s*$') then F.OpenBeastJournal();return end
            if (text or ''):lower():match('^%s*trainingdebug%s*$') then F.DebugPetTraining(); return end
            if (text or ''):lower():match('^%s*pet%s*$') then local s=F.PetStatusSettings();F.SetToolEnabled('pet',not s.enabled);return end
            if (text or ''):lower():match('^%s*weapons%s*$') then F.OpenWeaponComparisonSettings();return end
            if (text or ''):lower():match('^%s*abilities%s*$') then F.OpenPetAbilityBrowser();return end
            if (text or ''):lower():match('^%s*petsettings%s*$') then F.OpenPetStatusSettings();return end
            if (text or ''):lower():match('^%s*range%s*$') then local s=F.RangeSettings(); s.enabled=not s.enabled; F.UpdateRangeWindow(); return end
            if (text or ''):lower():match('^%s*ammodebug%s*$') then F.DebugAmmo(); return end
            if (text or ''):lower():match('^%s*$') or (text or ''):lower():match('^%s*config%s*$') then F.OpenConfig(); return end
            if (text or ''):lower():match('^%s*instance%s*$') then F.OpenInstanceSettings(); return end
            if (text or ''):lower():match('^%s*questdebug%s*$') then F.DebugQuestFood(); return end
            if (text or ''):lower():match('^%s*ammo%s*$') then F.OpenAmmoSettings(); return end
            if (text or ''):lower():match('^%s*foods%s*$') then F.OpenFoodList(); return end
            if F.ListCommand(text or '') then return end
            local cmd=(text or ''):lower():match('^%s*(.-)%s*$')
            if cmd~='on' and cmd~='off' then F.Print('/ht weapons; /ht abilities; /ht ammo; /ht foods; /ht on|off; /ht whitelist|blacklist add|remove <item link or ID>, list, clear. Shift-drag moves the button.'); return end
            F.db.enabled=cmd=='on'
            if InCombatLockdown() then F.Print('Visibility will update after combat.'); return end
            F.Refresh()
        end
        F.supported=F.CheckAPIs()
        if not F.supported then F.Print('Required Forever APIs are unavailable.'); return end
        for _,e in ipairs({'PLAYER_ENTERING_WORLD','PLAYER_REGEN_ENABLED','BAG_UPDATE_DELAYED','PLAYER_EQUIPMENT_CHANGED',
            'ITEM_LOCK_CHANGED','GET_ITEM_INFO_RECEIVED','UNIT_PET','UNIT_HAPPINESS',
            'UNIT_AURA','SPELLS_CHANGED','UNIT_SPELLCAST_SUCCEEDED','UNIT_SPELLCAST_FAILED','UNIT_SPELLCAST_INTERRUPTED',
            'QUEST_LOG_UPDATE','QUEST_ACCEPTED','QUEST_REMOVED','QUEST_TURNED_IN'}) do loader:RegisterEvent(e) end
    end
    if not F.supported then return end
    if event=='ADDON_LOADED' or event=='PLAYER_ENTERING_WORLD' then F.QueueFoodEntryScan() end
    if event=='BAG_UPDATE_DELAYED' or event=='GET_ITEM_INFO_RECEIVED' or event=='ITEM_LOCK_CHANGED' or event=='UNIT_PET' then
        F.foodEntrySnapshot=nil
    end
    if event=='PLAYER_ENTERING_WORLD' then F.QueueInstanceCheck(); F.QueueAmmoEntryScan() end
    F.bagsDirty=true
    if event=='ADDON_LOADED' or event=='PLAYER_ENTERING_WORLD' or event=='PLAYER_REGEN_ENABLED'
        or event=='BAG_UPDATE_DELAYED' or event=='PLAYER_EQUIPMENT_CHANGED' or event=='GET_ITEM_INFO_RECEIVED' then F.ammoDirty=true end
    if event=='UNIT_SPELLCAST_SUCCEEDED' or event=='UNIT_SPELLCAST_FAILED' or event=='UNIT_SPELLCAST_INTERRUPTED' then
        F.HandleFeedCastEvent(event,a,c)
    end
    if InCombatLockdown() or F.clickInProgress then return end
    if not F.button then
        F.BuildUI()
        F.ticker=C_Timer.NewTicker(0.5,function() F.UpdateHappinessBorder(); F.Refresh(); F.CheckAmmoReminder(); F.CheckAmmoUpgradeNotifications(); F.CheckInstancePrompt(); F.CheckAspectPrompt(); F.UpdateAspectButton(); F.UpdateTrackingButton(); F.UpdateRangeWindow(); F.UpdatePetStatusWindow(); F.CheckPetAlerts() end)
    end
    if F.dragging then
        F.button:StopMovingOrSizing(); F.dragging=false
    end
    F.Refresh()
    F.UpdatePetStatusWindow()
end)
