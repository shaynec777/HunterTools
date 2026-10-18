local _,F=...
local function safe(v) return not issecretvalue or not issecretvalue(v) end
local function query(fn,...)
    if type(fn)~='function' then return end
    local ok,a,b=pcall(fn,...);if not ok or not safe(a) then return end
    if not safe(b) then b=nil end
    return a,b
end
function F.TrackingSettings()
    if type(F.db.tracking)~='table' then F.db.tracking={} end
    local s=F.db.tracking
    if type(s.enabled)~='boolean' then s.enabled=true end
    if type(s.locked)~='boolean' then s.locked=false end
    if type(s.reminder)~='boolean' then s.reminder=true end
    if type(s.intentionalNone)~='boolean' then s.intentionalNone=false end
    for key,default in pairs({x=-28,y=-180}) do
        if type(s[key])~='number' or s[key]~=s[key] or math.abs(s[key])>10000 then s[key]=default end
    end
    return s
end
function F.TrackingState()
    if InCombatLockdown() then return end
    local api=C_Minimap
    if not (api and api.GetNumTrackingTypes and api.GetTrackingInfo) then return end
    local count=query(api.GetNumTrackingTypes)
    if type(count)~='number' or count<0 or count>512 then return end
    local state={choices={},uncertain=false};local seen={}
    for i=1,count do
        local info=query(api.GetTrackingInfo,i)
        if type(info)~='table' then state.uncertain=true end
        if type(info)=='table' then
            if not safe(info.active) then state.uncertain=true end
            local id=info.spellID
            if not safe(id) then id=nil end
            if not id and api.GetTrackingFilter then
                local filter=query(api.GetTrackingFilter,i)
                if type(filter)=='table' and safe(filter.spellID) then id=filter.spellID end
            end
            local name=info.name
            if type(id)=='number' and id>0 and safe(name) and type(name)=='string' and name~='' and not name:find('[\r\n]') and not seen[id] then
                -- Native spell-backed tracking includes learned profession abilities;
                -- omit minimap service filters, which are not castable tracking spells.
                local known=true
                if C_SpellBook and C_SpellBook.IsSpellKnown then local value=query(C_SpellBook.IsSpellKnown,id);if value==nil then state.uncertain=true end;known=value==true end
                if known and #state.choices<32 then
                    local active=safe(info.active) and info.active==true
                    local row={id=id,name=name,active=active,texture=safe(info.texture) and info.texture or nil}
                    state.choices[#state.choices+1]=row;seen[id]=true
                    if active and not state.active then state.active=row end
                end
            end
        end
    end
    return state
end
function F.BuildTrackingButton()
    if F.trackingButton or InCombatLockdown() then return end
    local b=CreateFrame('Button','HunterToolsTrackingButton',UIParent,'SecureHandlerClickTemplate,BackdropTemplate');F.trackingButton=b
    b:SetSize(44,44);b:SetClampedToScreen(true);b:SetMovable(true);b:EnableMouse(true)
    local s=F.TrackingSettings();b:SetPoint('CENTER',UIParent,'CENTER',s.x,s.y)
    b:SetBackdrop({bgFile='Interface\\Buttons\\WHITE8X8',edgeFile='Interface\\DialogFrame\\UI-DialogBox-Border',edgeSize=12})
    b:SetBackdropColor(0.04,0.06,0.05,1)
    b.icon=b:CreateTexture(nil,'ARTWORK');b.icon:SetPoint('TOPLEFT',5,-5);b.icon:SetPoint('BOTTOMRIGHT',-5,5);b.icon:SetTexture(132328)
    b.empty=b:CreateFontString(nil,'OVERLAY','GameFontNormalLarge');b.empty:SetPoint('CENTER');b.empty:SetText('?')
    b:RegisterForDrag('LeftButton');b:RegisterForClicks('RightButtonUp')
    b:SetScript('OnDragStart',function(self)
        if IsShiftKeyDown() and not InCombatLockdown() and not F.TrackingSettings().locked then self:StartMoving();F.trackingButtonDragging=true end
    end)
    b:SetScript('OnDragStop',function()
        if not F.trackingButtonDragging then return end
        F.trackingButtonDragStopPending=true
        F.FinishTrackingButtonDrag()
    end)
    b:SetScript('OnEnter',function(self)
        if not GameTooltip then return end
        GameTooltip:SetOwner(self,'ANCHOR_RIGHT');GameTooltip:AddLine('HunterTools tracking',1,0.82,0)
        GameTooltip:AddLine(self.trackingName or 'No active tracking confirmed',1,1,1)
        GameTooltip:AddLine('Right-click: choose a tracking ability.',0.8,0.9,0.8,true)
        GameTooltip:AddLine(F.TrackingSettings().locked and 'Position locked. /ht tracking opens settings.' or 'Shift + left-drag to move. /ht tracking opens settings.',0.8,0.8,0.8,true)
        GameTooltip:Show()
    end)
    b:SetScript('OnLeave',function() if GameTooltip then GameTooltip:Hide() end end)
    local p=CreateFrame('Frame','HunterToolsTrackingPicker',UIParent,'SecureHandlerStateTemplate,BackdropTemplate');F.trackingPicker=p
    p:SetSize(500,170);p:SetPoint('TOPLEFT',b,'TOPRIGHT',6,0);p:SetFrameStrata('DIALOG');p:SetClampedToScreen(true)
    p:SetBackdrop({bgFile='Interface\\Buttons\\WHITE8X8',edgeFile='Interface\\DialogFrame\\UI-DialogBox-Border',edgeSize=18});p:SetBackdropColor(0.035,0.047,0.044,1)
    p.title=p:CreateFontString(nil,'OVERLAY','GameFontNormal');p.title:SetPoint('TOPLEFT',20,-20);p.title:SetText('Choose tracking')
    p:SetAttribute('_onstate-combat',[[if newstate == 'combat' then self:Hide() end]])
    RegisterStateDriver(p,'combat','[combat] combat; peace')
    p.help=p:CreateFontString(nil,'OVERLAY','GameFontHighlightSmall');p.help:SetPoint('BOTTOM',0,12);p.help:SetText('Click to choose. Shift-drag to move outside combat.')
    local keep=CreateFrame('Button',nil,p,'UIPanelButtonTemplate');keep:SetSize(222,26);keep:SetPoint('BOTTOMLEFT',20,32);keep:SetText('Stay without tracking')
    keep:SetScript('OnClick',function() if InCombatLockdown() then return end;F.TrackingSettings().intentionalNone=true;p:Hide() end)
    local later=CreateFrame('Button',nil,p,'UIPanelButtonTemplate');later:SetSize(222,26);later:SetPoint('BOTTOMRIGHT',-20,32);later:SetText('Later (5 minutes)')
    later:SetScript('OnClick',function() if InCombatLockdown() then return end;F.trackingSnoozeUntil=GetTime()+300;p:Hide() end)
    p.keep=keep;p.later=later
    p.buttons={}
    for i=1,32 do
        local choice=CreateFrame('Button',nil,p,'SecureActionButtonTemplate,UIPanelButtonTemplate');p.buttons[i]=choice
        choice:SetSize(222,26);choice:SetPoint('TOPLEFT',20+((i-1)%2)*238,-48-math.floor((i-1)/2)*30)
        choice.trackingIcon=choice:CreateTexture(nil,'OVERLAY');choice.trackingIcon:SetSize(20,20);choice.trackingIcon:SetPoint('LEFT',8,0)
        local caption=choice:GetFontString()
        if caption then caption:ClearAllPoints();caption:SetPoint('LEFT',36,0);caption:SetPoint('RIGHT',-8,0);caption:SetJustifyH('LEFT') end
        choice:RegisterForClicks('LeftButtonUp');choice:SetAttribute('useOnKeyDown',false);choice:SetAttribute('type','spell')
        choice:SetScript('PostClick',function() if not InCombatLockdown() then p:Hide();F.trackingCheckAt=GetTime()+1 end end)
        if SecureHandlerWrapScript then
            SecureHandlerWrapScript(choice,'OnClick',p,[[return nil, true]],[[self:GetParent():Hide()]])
        end
    end
    SecureHandlerSetFrameRef(b,'picker',p)
    b:SetAttribute('_onclick',[[
        if button == 'RightButton' then
            local picker = self:GetFrameRef('picker')
            if picker:IsShown() then picker:Hide() else picker:Show() end
        end
    ]])
    if F.MakeMovableAlert then F.MakeMovableAlert(p,'tracking') end
    p:Hide();b:Hide()
end
function F.FinishTrackingButtonDrag()
    if InCombatLockdown() or not F.trackingButtonDragStopPending then return end
    local b=F.trackingButton
    if not b then return end
    b:StopMovingOrSizing()
    F.trackingButtonDragging=false;F.trackingButtonDragStopPending=nil
    local x,y=query(b.GetCenter,b);local px,py=query(UIParent.GetCenter,UIParent)
    if type(x)=='number' and type(y)=='number' and type(px)=='number' and type(py)=='number' then
        local settings=F.TrackingSettings();settings.x=x-px;settings.y=y-py
        b:ClearAllPoints();b:SetPoint('CENTER',UIParent,'CENTER',settings.x,settings.y)
    end
end
function F.UpdateTrackingButton()
    if not F.db or InCombatLockdown() then return end
    F.FinishTrackingButtonDrag()
    local _,class=query(UnitClass,'player')
    local settings=F.TrackingSettings()
    if class~='HUNTER' or (not settings.enabled and not settings.reminder) then
        if F.trackingButton then F.trackingPicker:Hide();F.trackingButton:Hide() end
        return
    end
    F.BuildTrackingButton();local b,p=F.trackingButton,F.trackingPicker
    local state=F.TrackingState()
    if not state then p:Hide();b:Hide();return end
    local active=state.active
    local texture=active and (active.texture or query(C_Spell and C_Spell.GetSpellTexture,active.id))
    b.icon:SetTexture(texture or 132328);b.icon:SetDesaturated(not active)
    b.empty:SetShown(active==nil);b.trackingName=active and active.name or nil
    local signature={}
    for _,choice in ipairs(state.choices) do signature[#signature+1]=tostring(choice.id) end
    signature=table.concat(signature,':')
    if signature~=p.signature then
        p:Hide();p.signature=signature
        for i,choice in ipairs(p.buttons) do
            local spell=state.choices[i]
            choice:SetAttribute('spell',spell and spell.id or nil);choice:SetText(spell and spell.name or '');choice:SetShown(spell~=nil)
            local icon=spell and (spell.texture or query(C_Spell and C_Spell.GetSpellTexture,spell.id))
            choice.trackingIcon:SetTexture(icon or 132328)
        end
        p:SetHeight(110+math.max(1,math.ceil(#state.choices/2))*30)
        p.title:SetText(#state.choices>0 and 'Choose tracking' or 'No learned tracking abilities available')
        if F.FinishMenu then F.FinishMenu(p,500,110+math.max(1,math.ceil(#state.choices/2))*30) end
    end
    for i,choice in ipairs(p.buttons) do
        local spell=state.choices[i]
        if spell then choice:SetText((spell.active and '|cff86d59c* |r' or '')..spell.name) end
    end
    p.title:SetText(#state.choices==0 and 'No learned tracking abilities available' or (active and 'Choose tracking' or 'No tracking active - choose tracking'))
    b:SetShown(settings.enabled)
    if state.active then
        settings.intentionalNone=false;F.trackingMissingSince=nil
        if p.autoPrompt then p:Hide();p.autoPrompt=nil end
        return
    end
    if not settings.reminder or settings.intentionalNone or state.uncertain or #state.choices==0 then
        F.trackingMissingSince=nil
        if p.autoPrompt then p:Hide();p.autoPrompt=nil end
        return
    end
    local paused=query(UnitIsDeadOrGhost,'player') or query(IsMounted) or query(UnitOnTaxi,'player') or query(UnitInVehicle,'player')
    local menu=(F.AspectMenuOpen and F.AspectMenuOpen('trackingPicker')) or (F.aspectPrompt and F.aspectPrompt:IsShown()) or (F.instancePrompt and F.instancePrompt:IsShown())
    if paused or menu then
        F.trackingMissingSince=nil
        if p.autoPrompt then p:Hide();p.autoPrompt=nil end
        return
    end
    F.trackingMissingSince=F.trackingMissingSince or GetTime()
    if GetTime()-F.trackingMissingSince>=3 and GetTime()>=(F.trackingSnoozeUntil or 0) and GetTime()>=(F.trackingCheckAt or 0) then
        p.autoPrompt=true;p:Show()
    end
end
function F.ResetTrackingButton()
    if InCombatLockdown() then return end
    local s=F.TrackingSettings();s.x=-28;s.y=-180
    if F.trackingButton then F.trackingButton:ClearAllPoints();F.trackingButton:SetPoint('CENTER',UIParent,'CENTER',s.x,s.y) end
end

function F.OpenTrackingSettings()
    if InCombatLockdown() then F.Print('Open tracking settings after combat.');return end
    F.HideConfigPages()
    if not F.trackingSettingsPanel then
        local p=CreateFrame('Frame','HunterToolsTrackingSettings',UIParent,'BackdropTemplate');F.trackingSettingsPanel=p
        p:SetSize(590,390);p:SetPoint('CENTER');p:SetFrameStrata('DIALOG')
        p:SetBackdrop({bgFile='Interface\\DialogFrame\\UI-DialogBox-Background',edgeFile='Interface\\DialogFrame\\UI-DialogBox-Border',edgeSize=24})
        table.insert(UISpecialFrames,'HunterToolsTrackingSettings')
        local close=CreateFrame('Button',nil,p,'UIPanelCloseButton');close:SetPoint('TOPRIGHT',-4,-4)
        F.MenuText(p,'Tracking button',28,-26,530,'GameFontNormalLarge')
        local function check(message,y,field)
            local c=CreateFrame('CheckButton',nil,p,'UICheckButtonTemplate');c:SetPoint('TOPLEFT',24,y)
            local label=c:CreateFontString(nil,'OVERLAY','GameFontHighlight');label:SetPoint('LEFT',c,'RIGHT',2,0);label:SetText(message)
            c:SetScript('OnClick',function()
                if InCombatLockdown() then c:SetChecked(F.TrackingSettings()[field]);return end
                F.TrackingSettings()[field]=c:GetChecked() and true or false;F.UpdateTrackingButton()
            end)
            return c
        end
        p.enabled=check('Show movable tracking button',-75,'enabled')
        p.locked=check('Lock tracking button position',-115,'locked')
        p.reminder=check('Warn and offer choices when nothing is tracked',-155,'reminder')
        F.MenuText(p,'Right-click to choose learned tracking, including profession tracking such as Find Herbs and Find Minerals. Shift + left-drag to move outside combat. The icon follows active tracking; green * marks active choices. Prepared choices remain clickable in combat; updates wait until combat ends.',30,-210,530)
        local reset=CreateFrame('Button',nil,p,'UIPanelButtonTemplate');reset:SetSize(230,27);reset:SetPoint('BOTTOMLEFT',30,30);reset:SetText('Reset tracking position');reset:SetScript('OnClick',F.ResetTrackingButton)
        local back=CreateFrame('Button',nil,p,'UIPanelButtonTemplate');back:SetSize(230,27);back:SetPoint('BOTTOMRIGHT',-30,30);back:SetText('Back to tools');back:SetScript('OnClick',F.OpenConfig)
    end
    local p=F.trackingSettingsPanel;local s=F.TrackingSettings()
    p.enabled:SetChecked(s.enabled);p.locked:SetChecked(s.locked);p.reminder:SetChecked(s.reminder)
    if F.FinishMenu then F.FinishMenu(p,590,390) end;p:Show()
end
