local _,F=...
local function safe(v) return not issecretvalue or not issecretvalue(v) end
local function query(fn,...)
    if type(fn)~='function' then return end
    local ok,a,b=pcall(fn,...);if not ok or not safe(a) then return end
    if not safe(b) then b=nil end
    return a,b
end
function F.BuildAspectButton()
    if F.aspectButton or InCombatLockdown() then return end
    local b=CreateFrame('Button','HunterToolsAspectButton',UIParent,'SecureHandlerClickTemplate,BackdropTemplate');F.aspectButton=b
    b:SetSize(44,44);b:SetClampedToScreen(true);b:SetMovable(true);b:EnableMouse(true)
    local s=F.AspectSettings().button;b:SetPoint('CENTER',UIParent,'CENTER',s.x,s.y)
    b:SetBackdrop({bgFile='Interface\\Buttons\\WHITE8X8',edgeFile='Interface\\DialogFrame\\UI-DialogBox-Border',edgeSize=12})
    b:SetBackdropColor(0.04,0.06,0.05,1)
    b.icon=b:CreateTexture(nil,'ARTWORK');b.icon:SetPoint('TOPLEFT',5,-5);b.icon:SetPoint('BOTTOMRIGHT',-5,5);b.icon:SetTexture(136076)
    b.empty=b:CreateFontString(nil,'OVERLAY','GameFontNormalLarge');b.empty:SetPoint('CENTER');b.empty:SetText('?')
    b:RegisterForDrag('LeftButton');b:RegisterForClicks('RightButtonUp')
    b:SetScript('OnDragStart',function(self)
        if not InCombatLockdown() and not F.AspectSettings().button.locked then self:StartMoving();F.aspectButtonDragging=true end
    end)
    b:SetScript('OnDragStop',function()
        if not F.aspectButtonDragging then return end
        F.aspectButtonDragStopPending=true
        F.FinishAspectButtonDrag()
    end)
    b:SetScript('OnEnter',function(self)
        if not GameTooltip then return end
        GameTooltip:SetOwner(self,'ANCHOR_RIGHT');GameTooltip:AddLine('HunterTools aspects',1,0.82,0)
        GameTooltip:AddLine(self.aspectName or 'No active aspect confirmed',1,1,1)
        GameTooltip:AddLine('Right-click: choose a learned aspect.',0.8,0.9,0.8,true)
        GameTooltip:AddLine(F.AspectSettings().button.locked and 'Position locked. /ht aspects opens settings.' or 'Left-drag to move. /ht aspects opens settings.',0.8,0.8,0.8,true)
        GameTooltip:Show()
    end)
    b:SetScript('OnLeave',function() if GameTooltip then GameTooltip:Hide() end end)
    local p=CreateFrame('Frame','HunterToolsAspectPicker',b,'SecureHandlerStateTemplate,BackdropTemplate');F.aspectPicker=p
    p:SetSize(300,170);p:SetPoint('TOPLEFT',b,'TOPRIGHT',6,0);p:SetFrameStrata('DIALOG');p:SetClampedToScreen(true)
    p:SetBackdrop({bgFile='Interface\\Buttons\\WHITE8X8',edgeFile='Interface\\DialogFrame\\UI-DialogBox-Border',edgeSize=18});p:SetBackdropColor(0.035,0.047,0.044,1)
    p.title=p:CreateFontString(nil,'OVERLAY','GameFontNormal');p.title:SetPoint('TOPLEFT',20,-20);p.title:SetText('Choose a learned aspect')
    p.help=p:CreateFontString(nil,'OVERLAY','GameFontHighlightSmall');p.help:SetPoint('BOTTOM',0,12);p.help:SetText('Right-click the aspect button to close.')
    p.buttons={}
    for i=1,8 do
        local choice=CreateFrame('Button',nil,p,'SecureActionButtonTemplate,UIPanelButtonTemplate');p.buttons[i]=choice
        choice:SetSize(260,28);choice:SetPoint('TOPLEFT',20,-48-(i-1)*34)
        choice.aspectIcon=choice:CreateTexture(nil,'OVERLAY');choice.aspectIcon:SetSize(20,20);choice.aspectIcon:SetPoint('LEFT',8,0)
        local caption=choice:GetFontString()
        if caption then caption:ClearAllPoints();caption:SetPoint('LEFT',36,0);caption:SetPoint('RIGHT',-8,0);caption:SetJustifyH('LEFT') end
        choice:RegisterForClicks('LeftButtonUp');choice:SetAttribute('useOnKeyDown',false);choice:SetAttribute('type','spell')
        choice:SetScript('PostClick',function() if not InCombatLockdown() then p:Hide();F.aspectCheckAt=GetTime()+1 end end)
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
    p:Hide();b:Hide()
end
function F.FinishAspectButtonDrag()
    if InCombatLockdown() or not F.aspectButtonDragStopPending then return end
    local b=F.aspectButton
    if not b then return end
    b:StopMovingOrSizing()
    F.aspectButtonDragging=false;F.aspectButtonDragStopPending=nil
    local x,y=query(b.GetCenter,b);local px,py=query(UIParent.GetCenter,UIParent)
    if type(x)=='number' and type(y)=='number' and type(px)=='number' and type(py)=='number' then
        local settings=F.AspectSettings().button;settings.x=x-px;settings.y=y-py
        b:ClearAllPoints();b:SetPoint('CENTER',UIParent,'CENTER',settings.x,settings.y)
    end
end
function F.UpdateAspectButton()
    if not F.db or InCombatLockdown() then return end
    F.FinishAspectButtonDrag()
    local _,class=query(UnitClass,'player')
    local settings=F.AspectSettings().button
    if class~='HUNTER' or not settings.enabled then
        if F.aspectButton then F.aspectPicker:Hide();F.aspectButton:Hide() end
        return
    end
    F.BuildAspectButton();local b,p=F.aspectButton,F.aspectPicker
    local state=F.AspectState()
    if not state then p:Hide();b:Hide();return end
    local active=state.active
    local texture=active and query(C_Spell and C_Spell.GetSpellTexture,active.id)
    b.icon:SetTexture(texture or 136076);b.icon:SetDesaturated(not active)
    b.empty:SetShown(active==nil);b.aspectName=active and active.name or nil
    local signature={}
    for _,choice in ipairs(state.choices) do signature[#signature+1]=tostring(choice.id) end
    signature=table.concat(signature,':')
    if signature~=p.signature then
        p:Hide();p.signature=signature
        for i,choice in ipairs(p.buttons) do
            local spell=state.choices[i]
            choice:SetAttribute('spell',spell and spell.id or nil);choice:SetText(spell and spell.name or '');choice:SetShown(spell~=nil)
            local icon=spell and query(C_Spell and C_Spell.GetSpellTexture,spell.id)
            choice.aspectIcon:SetTexture(icon or 136076)
        end
        p:SetHeight(80+math.max(1,#state.choices)*34)
        p.title:SetText(#state.choices>0 and 'Choose a learned aspect' or 'No learned aspects available')
        if F.FinishMenu then F.FinishMenu(p,300,80+math.max(1,#state.choices)*34) end
    end
    b:Show()
end
function F.ResetAspectButton()
    if InCombatLockdown() then return end
    local s=F.AspectSettings().button;s.x=-80;s.y=-180
    if F.aspectButton then F.aspectButton:ClearAllPoints();F.aspectButton:SetPoint('CENTER',UIParent,'CENTER',s.x,s.y) end
end
