local _,F=...
local function safe(v) return not issecretvalue or not issecretvalue(v) end
local function query(fn,...)
    if type(fn)~='function' then return nil,nil,false end
    local ok,a,b=pcall(fn,...)
    if not ok or not safe(a) then return nil,nil,false end
    if not safe(b) then b=nil end
    return a,b,true
end
-- Hunter aspect spell families from the retained Forever client spell records.
-- Optional Viper/Falcon variants appear only if this character actually knows them.
local aspects={
    {key='hawk',ids={13165,14318,14319,14320,14321,14322,25296}},
    {key='monkey',ids={13163}}, {key='beast',ids={13161,1299445,1299446,1299447}},
    {key='wild',ids={20043,20190}}, {key='viper',ids={34074,415423,415424}},
    {key='falcon',ids={469145}}, {key='cheetah',ids={5118}}, {key='pack',ids={13159}},
}
function F.AspectSettings()
    if type(F.db.aspects)~='table' then F.db.aspects={} end
    local s=F.db.aspects
    if type(s.enabled)~='boolean' then s.enabled=true end
    if type(s.intentionalNone)~='boolean' then s.intentionalNone=false end
    if type(s.button)~='table' then s.button={} end
    if type(s.button.enabled)~='boolean' then s.button.enabled=true end
    if type(s.button.locked)~='boolean' then s.button.locked=false end
    if type(s.button.x)~='number' then s.button.x=-80 end
    if type(s.button.y)~='number' then s.button.y=-180 end
    return s
end
function F.AspectState()
    if query(InCombatLockdown) then return end
    if not (C_SpellBook and C_SpellBook.IsSpellKnown and C_UnitAuras and C_UnitAuras.GetAuraDataBySpellName) then return end
    local result={choices={},uncertain=false}
    for _,family in ipairs(aspects) do
        local choice
        for _,id in ipairs(family.ids) do
            local known=query(C_SpellBook.IsSpellKnown,id)
            if known==nil then result.uncertain=true end
            if known then
                local name=query(C_Spell and C_Spell.GetSpellName,id)
                if type(name)=='string' and name~='' and not name:find('[\r\n]') then choice={key=family.key,id=id,name=name}
                else result.uncertain=true end
            end
        end
        if choice then
            result.choices[#result.choices+1]=choice
            local aura,_,readable=query(C_UnitAuras.GetAuraDataBySpellName,'player',choice.name,'HELPFUL')
            if not readable then result.uncertain=true end
            if type(aura)=='table' then
                if safe(aura.sourceUnit) and aura.sourceUnit=='player' then
                    result.active=choice
                    if safe(aura.auraInstanceID) and type(aura.auraInstanceID)=='number' then result.activeAuraID=aura.auraInstanceID end
                elseif not safe(aura.sourceUnit) or aura.sourceUnit==nil then result.uncertain=true end
            end
        end
    end
    if result.active and not result.uncertain then
        F.lastOwnAspectAura={id=result.activeAuraID,name=result.active.name}
    elseif not result.uncertain then F.lastOwnAspectAura=nil end
    return result
end
function F.ObserveAspectCancellation(unit,auraID)
    local last=F.lastOwnAspectAura
    if not F.db or not safe(unit) or unit~='player' or not safe(auraID) or type(auraID)~='number' then return end
    if last and last.id==auraID then
        -- Observe the client's explicit cancellation request; never cancel an aura ourselves.
        F.AspectSettings().intentionalNone=true
        F.aspectCancellationPending={id=auraID,untilTime=GetTime()+3}
    end
end
if hooksecurefunc and C_UnitAuras and type(C_UnitAuras.CancelAuraByInstanceID)=='function' then
    pcall(hooksecurefunc,C_UnitAuras,'CancelAuraByInstanceID',F.ObserveAspectCancellation)
end
local function hide()
    if F.aspectPrompt and not query(InCombatLockdown) then F.aspectPrompt:Hide() end
end
function F.KeepNoAspect()
    if query(InCombatLockdown) then return end
    F.AspectSettings().intentionalNone=true
    hide()
end
function F.DismissPackChoice()
    if F.instanceEntryEffects then F.instanceEntryEffects.pack=false end
    F.instanceAspectRequest=nil
    hide()
end
function F.BuildAspectPrompt()
    if F.aspectPrompt or query(InCombatLockdown) then return end
    local p=CreateFrame('Frame','HunterToolsAspectPrompt',UIParent,'SecureHandlerStateTemplate,BackdropTemplate');F.aspectPrompt=p
    p:SetSize(500,300);p:SetPoint('CENTER',0,90);p:SetFrameStrata('DIALOG');p:SetClampedToScreen(true)
    p:SetBackdrop({bgFile='Interface\\DialogFrame\\UI-DialogBox-Background',edgeFile='Interface\\DialogFrame\\UI-DialogBox-Border',edgeSize=24})
    p:SetAttribute('_onstate-combat',[[if newstate == 'combat' then self:Hide() end]])
    RegisterStateDriver(p,'combat','[combat] combat; peace')
    local function label(y,font)
        local t=p:CreateFontString(nil,'OVERLAY',font or 'GameFontHighlightSmall');t:SetPoint('TOPLEFT',20,y);t:SetWidth(460);t:SetJustifyH('LEFT');return t
    end
    p.title=label(-20,'GameFontNormalLarge');p.message=label(-54);p.message:SetHeight(36)
    p.buttons={}
    for i=1,8 do
        local b=CreateFrame('Button',nil,p,'SecureActionButtonTemplate,UIPanelButtonTemplate')
        b:SetSize(222,26);b:SetPoint('TOPLEFT',20+((i-1)%2)*238,-100-math.floor((i-1)/2)*30)
        b.aspectIcon=b:CreateTexture(nil,'OVERLAY');b.aspectIcon:SetSize(20,20);b.aspectIcon:SetPoint('LEFT',8,0)
        local caption=b:GetFontString()
        if caption then caption:ClearAllPoints();caption:SetPoint('LEFT',36,0);caption:SetPoint('RIGHT',-8,0);caption:SetJustifyH('LEFT') end
        b:RegisterForClicks('LeftButtonUp');b:SetAttribute('useOnKeyDown',false);b:SetAttribute('type','spell')
        b:SetScript('PostClick',function() if not InCombatLockdown() then F.aspectCheckAt=GetTime()+1 end end)
        p.buttons[i]=b
    end
    p.growl=CreateFrame('Button',nil,p,'SecureActionButtonTemplate,UIPanelButtonTemplate');p.growl:SetSize(275,28);p.growl:SetPoint('TOPLEFT',26,-271)
    p.growl:RegisterForClicks('LeftButtonUp');p.growl:SetAttribute('useOnKeyDown',false);p.growl:SetAttribute('type','macro');p.growl:SetText('Disable pet Growl autocast')
    p.growl:SetScript('PostClick',function() if not InCombatLockdown() then F.instanceCheckAt=GetTime()+0.5 end end)
    p.keep=CreateFrame('Button',nil,p,'UIPanelButtonTemplate');p.keep:SetSize(275,28);p.keep:SetPoint('TOPLEFT',318,-271)
    p.keep:SetScript('OnClick',function()
        if InCombatLockdown() then return end
        if p.reason=='pack' then F.DismissPackChoice() else F.KeepNoAspect() end
    end)
    p.later=CreateFrame('Button',nil,p,'UIPanelButtonTemplate');p.later:SetSize(180,27);p.later:SetPoint('BOTTOMLEFT',26,48);p.later:SetText('Later (5 minutes)')
    p.later:SetScript('OnClick',function() if not InCombatLockdown() then F.aspectSnoozeUntil=GetTime()+300;hide() end end)
    p.disable=CreateFrame('Button',nil,p,'UIPanelButtonTemplate');p.disable:SetSize(275,27);p.disable:SetPoint('BOTTOMRIGHT',-26,48);p.disable:SetText('Turn off this reminder')
    p.disable:SetScript('OnClick',function()
        if InCombatLockdown() then return end
        if p.reason=='pack' then F.InstanceSettings().pack=false;F.DismissPackChoice()
        else F.AspectSettings().enabled=false;hide() end
    end)
    p.help=label(-354);p.help:SetText('Buttons cast only when you click. Combat pauses the chooser. No aspect is selected automatically.')
    if F.MakeMovableAlert then F.MakeMovableAlert(p,'aspectReminder') end
    p:Hide()
end
function F.ShowAspectChooser(reason,e,state)
    if query(InCombatLockdown) then return end
    if query(UnitIsDeadOrGhost,'player') or query(IsMounted) or query(UnitOnTaxi,'player') or query(UnitInVehicle,'player') then hide();return end
    if F.AspectMenuOpen() then hide();return end
    if GetTime()<(F.aspectSnoozeUntil or 0) or GetTime()<(F.aspectCheckAt or 0) then return end
    state=state or F.AspectState();if not state then return end
    if F.BuildAspectButton then F.BuildAspectButton() end
    F.BuildAspectPrompt();local p=F.aspectPrompt;p.reason=reason
    if p.alertDragging==true then return end
    p:ClearAllPoints()
    if F.aspectButton then p:SetPoint('TOPLEFT',F.aspectButton,'TOPRIGHT',6,0)
    else
        local position=F.AspectSettings().button
        p:SetPoint('TOPLEFT',UIParent,'CENTER',position.x+28,position.y+22)
    end
    if F.RestoreAlertPosition then F.RestoreAlertPosition(p,'aspectReminder') end
    p.title:SetText(reason=='pack' and 'Pack is on - choose another aspect' or 'Choose an aspect')
    p.message:SetText(reason=='pack' and 'Choose another aspect for this instance, or keep Pack.'
        or 'No aspect is active. Choose one, or stay without an aspect until you activate one again.')
    local index=0
    local inside,kind=query(IsInInstance)
    local avoidPack=reason=='pack' or (inside and (kind=='party' or kind=='raid'))
    for _,choice in ipairs(state.choices) do
        if not avoidPack or choice.key~='pack' then
            index=index+1;local b=p.buttons[index]
            b:SetText(choice.name);b:SetAttribute('spell',choice.id);b:Show()
            local icon=query(C_Spell and C_Spell.GetSpellTexture,choice.id)
            b.aspectIcon:SetTexture(icon or 136076)
        end
    end
    for i=index+1,#p.buttons do p.buttons[i]:SetAttribute('spell',nil);p.buttons[i]:Hide() end
    if index==0 then p.message:SetText(reason=='pack' and 'Pack is active, but no other learned aspect is available yet. You can keep Pack or defer this reminder.' or 'No learned aspects are available yet.') end
    p.keep:SetText(reason=='pack' and 'Keep Pack for this instance' or 'Stay without an aspect')
    local growl=e and e.growlOn and e.growl
    p.growl:SetAttribute('macrotext',growl and ('/petautocastoff '..growl) or '')
    p.growl:SetShown(growl~=nil and growl~=false)
    local row=104+math.max(1,math.ceil(index/2))*30
    p.growl:ClearAllPoints();p.growl:SetPoint('TOPLEFT',20,-row);p.growl:SetSize(222,26)
    p.keep:ClearAllPoints();p.keep:SetPoint('TOPLEFT',growl and 258 or 20,-row);p.keep:SetSize(growl and 222 or 460,26)
    p.later:ClearAllPoints();p.later:SetPoint('TOPLEFT',20,-row-32);p.later:SetSize(222,26)
    p.disable:ClearAllPoints();p.disable:SetPoint('TOPLEFT',258,-row-32);p.disable:SetSize(222,26)
    p.help:ClearAllPoints();p.help:SetPoint('TOPLEFT',20,-row-68);p.help:SetWidth(460)
    p.help:SetText('Click to cast. Shift-drag to move outside combat.')
    local height=row+100;p:SetSize(500,height)
    if F.FinishMenu then F.FinishMenu(p,500,height) end
    p:Show()
end
function F.AspectMenuOpen(exclude)
    for _,key in ipairs({'configPanel','aspectSettingsPanel','instanceSettingsPanel','foodPanel','ammoPanel','rangeSettingsPanel','petStatusSettingsPanel','petAbilityBrowser','beastJournalPanel','aspectPicker','petAlertPanel','trackingSettingsPanel','trackingPicker','petListPanel','animalSettingsPanel','ammoUpgradePanel','protectionPanel','weaponSettingsPanel'}) do
        local p=F[key];if key~=exclude and p and p:IsShown() then return true end
    end
    return false
end
function F.CheckAspectPrompt()
    if not F.db or query(InCombatLockdown) then return end
    local _,class=query(UnitClass,'player')
    if class~='HUNTER' or query(UnitIsDeadOrGhost,'player') or query(IsMounted) or query(UnitOnTaxi,'player') or query(UnitInVehicle,'player') then hide();return end
    local s=F.AspectSettings();local state=F.AspectState()
    if not state then hide();return end
    if state.active then
        local cancellation=F.aspectCancellationPending
        if not cancellation or cancellation.id~=state.activeAuraID or GetTime()>cancellation.untilTime then
            s.intentionalNone=false;F.aspectCancellationPending=nil
        end
        F.aspectMissingSince=nil
    else F.aspectCancellationPending=nil end
    if F.instanceAspectRequest then
        local _,kind=query(IsInInstance)
        if kind~='party' and kind~='raid' then F.instanceAspectRequest=nil
        elseif state.active and state.active.key=='pack' then return -- Entry check owns this dialog.
        else F.instanceAspectRequest=nil;hide() end
    end
    if state.active or state.uncertain or #state.choices==0 or not s.enabled or s.intentionalNone then F.aspectMissingSince=nil;hide();return end
    -- Avoid warning during login/aura loading and the moment between aspect swaps.
    F.aspectMissingSince=F.aspectMissingSince or GetTime()
    if GetTime()-F.aspectMissingSince<3 then return end
    if F.instancePrompt and F.instancePrompt:IsShown() then return end
    F.ShowAspectChooser('missing',nil,state)
end
function F.OpenAspectSettings()
    if InCombatLockdown() then F.Print('Open aspect settings after combat.');return end
    F.HideConfigPages()
    if not F.aspectSettingsPanel then
        local p=CreateFrame('Frame','HunterToolsAspectSettings',UIParent,'BackdropTemplate');F.aspectSettingsPanel=p
        p:SetSize(640,480);p:SetPoint('CENTER');p:SetFrameStrata('DIALOG');p:SetClampedToScreen(true)
        p:SetBackdrop({bgFile='Interface\\DialogFrame\\UI-DialogBox-Background',edgeFile='Interface\\DialogFrame\\UI-DialogBox-Border',edgeSize=24})
        table.insert(UISpecialFrames,'HunterToolsAspectSettings')
        local close=CreateFrame('Button',nil,p,'UIPanelCloseButton');close:SetPoint('TOPRIGHT',-4,-4)
        local title=p:CreateFontString(nil,'OVERLAY','GameFontNormalLarge');title:SetPoint('TOPLEFT',28,-26);title:SetText('Aspect reminders')
        local function check(message,y,action)
            local b=CreateFrame('CheckButton',nil,p,'UICheckButtonTemplate');b:SetPoint('TOPLEFT',25,y)
            local t=b:CreateFontString(nil,'OVERLAY','GameFontHighlight');t:SetPoint('LEFT',b,'RIGHT',2,0);t:SetText(message)
            b:SetScript('OnClick',function() if not InCombatLockdown() then action(b:GetChecked() and true or false) end end);return b
        end
        p.enabled=check('Suggest an aspect when none is active',-75,function(v) F.AspectSettings().enabled=v;if not v then hide() end end)
        p.pack=check('Suggest another aspect when Pack is on at instance entry',-115,function(v) F.InstanceSettings().pack=v end)
        p.intent=check('I am intentionally using no aspect',-155,function(v) F.AspectSettings().intentionalNone=v;F.aspectMissingSince=nil;if v then hide() end end)
        p.button=check('Show movable aspect button (right-click to choose)',-195,function(v) F.AspectSettings().button.enabled=v;if F.UpdateAspectButton then F.UpdateAspectButton() end end)
        p.lock=check('Lock aspect button position',-235,function(v) F.AspectSettings().button.locked=v end)
        local help=p:CreateFontString(nil,'OVERLAY','GameFontHighlightSmall');help:SetPoint('TOPLEFT',30,-285);help:SetWidth(580);help:SetJustifyH('LEFT')
        help:SetText('An identifiable direct aspect cancellation, or Stay without an aspect, is remembered until you activate an aspect again. If a cancellation method cannot be identified, use Stay without an aspect. Pop-ups wait through combat, death, mounting and travel. Pack reminders respect the Dungeon checks toggle.')
        local reset=CreateFrame('Button',nil,p,'UIPanelButtonTemplate');reset:SetSize(230,27);reset:SetPoint('BOTTOM',0,75);reset:SetText('Reset aspect button position');reset:SetScript('OnClick',function() if F.ResetAspectButton then F.ResetAspectButton() end end)
        local back=CreateFrame('Button',nil,p,'UIPanelButtonTemplate');back:SetSize(200,27);back:SetPoint('BOTTOM',0,26);back:SetText('Back to tools');back:SetScript('OnClick',F.OpenConfig)
    end
    local p=F.aspectSettingsPanel;local s=F.AspectSettings()
    p.enabled:SetChecked(s.enabled);p.pack:SetChecked(F.InstanceSettings().pack);p.intent:SetChecked(s.intentionalNone)
    p.button:SetChecked(s.button.enabled);p.lock:SetChecked(s.button.locked)
    if F.FinishMenu then F.FinishMenu(p,640,480) end;p:Show()
end
