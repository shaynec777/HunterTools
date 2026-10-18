local _, F = ...
local function safe(v) return not issecretvalue or not issecretvalue(v) end
local function spellName(id)
    local name=C_Spell and C_Spell.GetSpellName and C_Spell.GetSpellName(id)
    if safe(name) and type(name)=='string' and not name:find('[\r\n]') then return name end
end

function F.InstanceEffects()
    if InCombatLockdown() then return nil end
    local growl,pack=spellName(6795),spellName(13159)
    local growlOn=false
    if growl and GetPetActionInfo then
        for slot=1,(NUM_PET_ACTION_SLOTS or 10) do
            local name,_,token,_,allowed,enabled=GetPetActionInfo(slot)
            if safe(name) and safe(token) and safe(allowed) and safe(enabled) then
                if token and type(name)=='string' then name=_G[name] end
                if name==growl and allowed and enabled then growlOn=true end
            end
        end
    end
    local aura=pack and C_UnitAuras and C_UnitAuras.GetAuraDataBySpellName
        and C_UnitAuras.GetAuraDataBySpellName('player',pack,'HELPFUL')
    local packOn=false
    if safe(aura) and aura and safe(aura.sourceUnit) then
        -- Another hunter's Pack cannot be cancelled by this player.
        packOn=aura.sourceUnit=='player'
    end
    return {growl=growl,pack=pack,growlOn=growlOn,packOn=packOn}
end

function F.InstanceEffectMacro(e,which)
    local lines={}
    if e.growlOn and (which=='growl' or which=='both') then
        table.insert(lines,'/petautocastoff '..e.growl)
    end
    -- Pack is replaced through an explicit aspect choice, never auto-cancelled.
    return table.concat(lines,'\n')
end

function F.BuildInstancePrompt()
    if F.instancePrompt or InCombatLockdown() then return end
    local p=CreateFrame('Frame','HunterToolsInstancePrompt',UIParent,'SecureHandlerStateTemplate,BackdropTemplate')
    F.instancePrompt=p
    p:SetSize(520,200); p:SetPoint('CENTER',0,100); p:SetFrameStrata('DIALOG')
    p:SetClampedToScreen(true)
    p:SetBackdrop({bgFile='Interface\\DialogFrame\\UI-DialogBox-Background',edgeFile='Interface\\DialogFrame\\UI-DialogBox-Border',edgeSize=24})
    p:SetAttribute('_onstate-combat',[[if newstate == 'combat' then self:Hide() end]])
    RegisterStateDriver(p,'combat','[combat] combat; peace')
    local title=p:CreateFontString(nil,'OVERLAY','GameFontNormalLarge')
    title:SetPoint('TOP',0,-20); title:SetText('Dungeon / raid check')
    p.message=p:CreateFontString(nil,'OVERLAY','GameFontHighlight')
    p.message:SetPoint('TOPLEFT',25,-55); p.message:SetWidth(470)
    p.buttons={}
    for i,spec in ipairs({{'growl','Disable Growl'}}) do
        local b=CreateFrame('Button',nil,p,'SecureActionButtonTemplate,UIPanelButtonTemplate')
        b:SetSize(145,26); b:SetPoint('BOTTOMLEFT',25+(i-1)*160,60)
        b:SetText(spec[2]); b:RegisterForClicks('LeftButtonUp'); b:SetAttribute('useOnKeyDown',false)
        b:SetAttribute('type','macro'); p.buttons[spec[1]]=b
        local choice=spec[1]
        b:SetScript('PostClick',function()
            if InCombatLockdown() then return end
            -- Let the client report the result before redrawing the choices.
            F.instanceCheckAt=GetTime()+0.5
        end)
    end
    local keep=CreateFrame('Button',nil,p,'UIPanelButtonTemplate')
    keep:SetSize(180,26); keep:SetPoint('BOTTOM',0,22); keep:SetText('Keep Growl on')
    keep:SetScript('OnClick',function()
        if InCombatLockdown() then return end
        F.instanceCheckPending=false; p:Hide()
    end)
    p:Hide()
end

function F.QueueInstanceCheck()
    F.instanceEntryEffects=nil
    F.instanceAspectRequest=nil
    F.aspectMissingSince=nil
    F.instanceCheckPending=true
    F.instanceCheckAt=GetTime()+1
end

function F.CheckInstancePrompt()
    if InCombatLockdown() then return end
    if F.db and F.db.instanceChecks and F.db.instanceChecks.enabled==false then
        F.instanceCheckPending=false
        F.instanceAspectRequest=nil
        if F.instancePrompt then F.instancePrompt:Hide() end
        if F.aspectPrompt and F.aspectPrompt.reason=='pack' then F.aspectPrompt:Hide() end
        return
    end
    local _,class=UnitClass('player')
    local inside,kind=IsInInstance()
    if class~='HUNTER' or not inside or (kind~='party' and kind~='raid') then
        F.instanceCheckPending=false
        F.instanceAspectRequest=nil
        if F.instancePrompt then F.instancePrompt:Hide() end
        if F.aspectPrompt and F.aspectPrompt.reason=='pack' then F.aspectPrompt:Hide() end
        return
    end
    if not F.instanceCheckPending or GetTime()<(F.instanceCheckAt or 0) then return end
    local e=F.InstanceEffects()
    if not e then return end
    local settings=F.db and F.db.instanceChecks or {}
    e.growlOn=e.growlOn and settings.growl~=false
    e.packOn=e.packOn and settings.pack~=false
    -- Snapshot entry state once. Later enabling an effect is an intentional choice.
    if not F.instanceEntryEffects then
        F.instanceEntryEffects={growl=e.growlOn,pack=e.packOn}
    end
    e.growlOn=e.growlOn and F.instanceEntryEffects.growl
    e.packOn=e.packOn and F.instanceEntryEffects.pack
    if not e.growlOn then F.instanceEntryEffects.growl=false end
    if not e.packOn then F.instanceEntryEffects.pack=false end
    if e.packOn and F.ShowAspectChooser then
        F.instanceAspectRequest=true
        if F.instancePrompt then F.instancePrompt:Hide() end
        F.ShowAspectChooser('pack',e)
        return
    end
    F.instanceAspectRequest=nil
    if F.aspectPrompt and F.aspectPrompt.reason=='pack' then F.aspectPrompt:Hide() end
    F.BuildInstancePrompt()
    local p=F.instancePrompt
    if not e.growlOn and not e.packOn then
        p:Hide()
        F.instanceCheckPending=false
        return
    end
    local effects={}
    if e.growlOn then table.insert(effects,(F.ReminderPetName() or 'Your pet').."'s Growl autocast") end
    if e.packOn then table.insert(effects,'your Aspect of the Pack') end
    p.message:SetText(table.concat(effects,' and ')..' is on. Disable Growl autocast for this dungeon or raid?')
    for which,b in pairs(p.buttons) do
        local macro=F.InstanceEffectMacro(e,which)
        b:SetAttribute('macrotext',macro)
        b:SetShown(macro~='' and (which~='both' or (e.growlOn and e.packOn)))
    end
    p:Show()
end
